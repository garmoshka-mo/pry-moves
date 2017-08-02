require 'pry' unless defined? Pry

module PryMoves
class Tracer
  def initialize(pry_start_options = {})
    @pry_start_options = pry_start_options   # Options to use for Pry.start
  end

  def run(&block)
    PryMoves.lock
    # For performance, disable any tracers while in the console.
    # Unfortunately doesn't work in 1.9.2 because of
    # http://redmine.ruby-lang.org/issues/3921. Works fine in 1.8.7 and 1.9.3.
    stop_tracing unless RUBY_VERSION == '1.9.2'

    return_value = nil
    PryMoves.is_open = true
    @command = catch(:breakout_nav) do      # Coordinates with PryMoves::Commands
      return_value = yield
      nil    # Nothing thrown == no navigational command
    end
    PryMoves.is_open = false

    # Adjust tracer based on command
    if @command
      init_command
      start_tracing
      post_action
    else
      stop_tracing if RUBY_VERSION == '1.9.2'
      PryMoves.semaphore.unlock
      if @pry_start_options[:pry_remote] && PryMoves.current_remote_server
        PryMoves.current_remote_server.teardown
      end
    end

    return_value
  end

  private

  def start_tracing
    Pry.config.disable_breakpoints = true
    Thread.current.set_trace_func method(:tracer).to_proc
  end

  def stop_tracing
    Pry.config.disable_breakpoints = false
    Thread.current.set_trace_func nil
  end

  def init_command
    @action = @command[:action]
    binding_ = @command[:binding]
    set_traced_method binding_

    case @action
    when :step
      @step_info_funcs = nil
      if (func = @command[:param])
        @step_info_funcs = [func]
        @step_info_funcs << 'initialize' if func == 'new'
      end
    when :finish
      @method_to_finish = @method
      @block_to_finish =
          (binding_.frame_type == :block) &&
              frame_digest(binding_)
    end
  end

  def post_action
    if @action == :debug
      #puts "CALLER:\n#{caller.join "\n"}\n"
      @command[:binding].eval @command[:param]
    end
  end

  def set_traced_method(binding)
    @recursion_level = 0

    method = binding.eval 'method(__method__) if __method__'
    if method
      source = method.source_location
      set_method({
       file: source[0],
       start: source[1],
       end: (source[1] + method.source.count("\n") - 1)
     })
    else
      set_method({file: binding.eval('__FILE__')})
    end
  end

  def set_method(method)
    #puts "set_traced_method #{method}"
    @method = method
  end

  def frame_digest(binding_)
    #puts "frame_digest for: #{binding_.eval '__callee__'}"
    Digest::MD5.hexdigest binding_.instance_variable_get('@iseq').disasm
  end

  def tracer(event, file, line, id, binding_, klass)
    #printf "%8s %s:%-2d %10s %8s rec:#{@recursion_level}\n", event, file, line, id, klass

    # Ignore traces inside pry-moves code
    return if file && TRACE_IGNORE_FILES.include?(File.expand_path(file))

    catch (:skip) do
      if send "trace_#{@action}", event, file, line, binding_
        Pry.start(binding_, @pry_start_options)

      # for cases when currently traced method called more times recursively
      elsif %w(call return).include?(event) and within_current_method?(file, line)
        @recursion_level += event == 'call' ? 1 : -1
      end
    end
  end

  def trace_step(event, file, line, binding_)
    return unless event == 'line'
    if @step_info_funcs
      method = binding_.eval('__callee__').to_s
      @step_info_funcs.any? {|pattern| method.include? pattern}
    else
      true
    end
  end

  def trace_next(event, file, line, binding_)
    traced_method_exit = (@recursion_level < 0 and %w(line call).include? event)
    if traced_method_exit
      # Set new traced method, because we left previous one
      set_traced_method binding_
      throw :skip if event == 'call'
    end

    event == 'line' and
      @recursion_level == 0 and
      within_current_method?(file, line)
  end

  def trace_finish(event, file, line, binding_)
    return unless event == 'line'
    return true if @recursion_level < 0 or @method_to_finish != @method

    # for finishing blocks inside current method
    if @block_to_finish
      within_current_method?(file, line) and
          @block_to_finish != frame_digest(binding_.of_caller(3))
    end
  end

  def trace_debug(event, file, line, binding_)
    event == 'line' and file == 'sand.rb' and line != 47
  end

  def debug_info(file, line, id)
    puts "📽  Action:#{@action}; recur:#{@recursion_level}; #{@method[:file]}:#{file}"
    puts "#{id} #{@method[:start]} > #{line} > #{@method[:end]}"
  end

  def within_current_method?(file, line)
    @method[:file] == file and (
      @method[:start].nil? or
      line.between?(@method[:start], @method[:end])
    )
  end

end
end