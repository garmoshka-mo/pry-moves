require 'pry' unless defined? Pry

module PryMoves
class Tracer
  def initialize(pry_start_options = {}, &block)
    @pry_start_options = pry_start_options   # Options to use for Pry.start
  end

  def run(&block)
    PryMoves.semaphore.lock unless PryMoves.semaphore.locked?
    # For performance, disable any tracers while in the console.
    # Unfortunately doesn't work in 1.9.2 because of
    # http://redmine.ruby-lang.org/issues/3921. Works fine in 1.8.7 and 1.9.3.
    stop_tracing unless RUBY_VERSION == '1.9.2'

    return_value = nil
    command = catch(:breakout_nav) do      # Coordinates with PryMoves::Commands
      return_value = yield
      {}    # Nothing thrown == no navigational command
    end

    # Adjust tracer based on command
    if process_command(command)
      start_tracing command
    else
      stop_tracing if RUBY_VERSION == '1.9.2'
      PryMoves.semaphore.unlock
      if @pry_start_options[:pry_remote] && PryMoves.current_remote_server
        PryMoves.current_remote_server.teardown
      end
    end

    return_value
  end

  def start_tracing(command)
    Pry.config.disable_breakpoints = true
    set_traced_method command[:binding]
    case @action
      when :finish
        @method_to_finish = @method
    end
    set_trace_func method(:tracer).to_proc
  end

  def stop_tracing
    Pry.config.disable_breakpoints = false
    set_trace_func nil
  end

  def process_command(command = {})
    @action = command[:action]

    case @action
      when :step
        @step_info_funcs = nil
        if command[:param]
          func = command[:param].to_sym
          @step_info_funcs = [func]
          @step_info_funcs << :initialize if func == :new
        end
    end

    [:step, :next, :finish].include? @action
  end


  private

  def set_traced_method(binding)
    @recursion_level = 0

    method = binding.eval 'method(__method__) if __method__'
    return set_method({file: binding.eval('__FILE__')}) unless method

    source = method.source_location
    set_method({
        file: source[0],
        start: source[1],
        end: (source[1] + method.source.count("\n") - 1)
        #thread: binding.eval 'Thread.current' # todo: Нужна проверка по треду?
    })
  end

  def set_method(method)
    #puts "set_traced_method #{method}"
    @method = method
  end

  def tracer(event, file, line, id, binding_, klass)
    #printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, klass
    # Ignore traces inside pry-moves code
    return if file && TRACE_IGNORE_FILES.include?(File.expand_path(file))

    traced_method_exit = (@recursion_level < 0 and %w(line call).include? event)
    # Set new traced method, because we left previous one
    set_traced_method binding_ if traced_method_exit

    case event
      when 'line'
        #debug_info file, line, id
        if break_here?(file, line, binding_, traced_method_exit)
          Pry.start(binding_, @pry_start_options)
        end
      when 'call', 'return'
        if within_current_method?(file, line) and !traced_method_exit
          recursion_step event
        end
    end
  end

  def debug_info(file, line, id)
    puts "📽  Action:#{@action}; recur:#{@recursion_level}; #{@method[:file]}:#{file}"
    puts "#{id} #{@method[:start]} > #{line} > #{@method[:end]}"
  end

  def break_here?(file, line, binding_, traced_method_exit)
    case @action
      when :step
        @step_info_funcs ?
            @step_info_funcs.include?(binding_.eval('__callee__'))
            : true
      when :finish
        @method_to_finish = @method if @method_to_finish != @method
      when :next
        @recursion_level == 0 and within_current_method?(file, line)
    end
  end

  def within_current_method?(file, line)
    @method[:file] == file and (
      @method[:start].nil? or
      line.between?(@method[:start], @method[:end])
    )
  end

  def recursion_step(event)
    #puts "recursion_step #{event} #{'call' ? 1 : -1}"
    @recursion_level += event == 'call' ? 1 : -1
  end

end
end