require 'digest'

require 'pry' unless defined? Pry

module PryMoves
class Tracer

  include PryMoves::TraceCommands
  include PryMoves::TracedMethod

  def initialize(command, pry_start_options)
    @command = command
    @pry_start_options = pry_start_options
  end

  def trace
    @action = @command[:action]
    #puts "COMMAND: #{@action}"
    binding_ = @command[:binding]
    set_traced_method binding_

    @recursion_level -= 1 if @pry_start_options.delete :exit_from_method

    case @action
    when :step
      @step_into_funcs = nil
      func = @command[:param]
      if func == '+'
        @step_in_everywhere = true
      elsif func
        @step_into_funcs = [func]
        @step_into_funcs << '=initialize' if func == 'new' or func == '=new'
        @caller_digest = frame_digest(binding_)
      end
    when :finish
      @method_to_finish = @method
      @block_to_finish =
          (binding_.frame_type == :block) &&
              frame_digest(binding_)
    when :next
      if @command[:param] == 'blockless'
        @stay_at_frame = frame_digest(binding_)
      end
    when :iterate
      @iteration_start_line = binding_.eval('__LINE__')
      @caller_digest = frame_digest(binding_)
    when :goto
      @goto_line = @command[:param].to_i
    end

    start_tracing
  end

  def stop_tracing
    trace_obj.set_trace_func nil
    Pry.config.disable_breakpoints = false
  end

  private

  def start_tracing
    #puts "##trace_obj #{trace_obj}"
    Pry.config.disable_breakpoints = true
    trace_obj.set_trace_func method(:tracing_func).to_proc
  end

  # You can't call set_trace_func or Thread.current.set_trace_func recursively
  # even in different threads 😪
  # But! 💡
  # The hack is - you can call Thread.current.set_trace_func
  # from inside of set_trace_func! 🤗
  def trace_obj
    Thread.current[:pry_moves_debug] ?
        Thread.current : Kernel
  end

  def frame_digest(binding_)
    #puts "frame_digest for: #{binding_.eval '__callee__'}"
    Digest::MD5.hexdigest binding_.instance_variable_get('@iseq').disasm
  end

  def tracing_func(event, file, line, id, binding_, klass)
    # printf ": %8s %s:%-2d %10s %8s rec:#{@recursion_level} st:#{@c_stack_level}\n", event, file, line, id, klass

    # Ignore traces inside pry-moves code
    return if file && TRACE_IGNORE_FILES.include?(File.expand_path(file))

    catch (:skip) do
      if send "trace_#{@action}", event, file, line, id, binding_
        stop_tracing
        Pry.start(binding_, @pry_start_options)

      # for cases when currently traced method called more times recursively
      elsif %w(call return).include?(event) and within_current_method?(file, line) and
          @method[:name] == id # fix for bug in traced_method: return for dynamic methods has line number inside of caller
        delta = event == 'call' ? 1 : -1
        #puts "recursion #{event}: #{delta}; changed: #{@recursion_level} => #{@recursion_level + delta}"
        @recursion_level += delta
      elsif %w(c-call c-return).include?(event)
        delta = event == 'c-call' ? 1 : -1
        @c_stack_level += delta
      end
    end
  end

  def method_matches?(method)
    @step_into_funcs.any? do |pattern|
      if pattern.start_with? '='
        "=#{method}" == pattern
      else
        method.include? pattern
      end
    end
  end

  def redirect_step_into?(binding_)
    return false unless binding_.local_variable_defined? :debug_redirect

    debug_redirect = binding_.local_variable_get(:debug_redirect)
    @step_into_funcs = [debug_redirect.to_s] if debug_redirect
    true
  end

  def debug_info(file, line, id)
    puts "📽  Action:#{@action}; recur:#{@recursion_level}; #{@method[:file]}:#{file}"
    puts "#{id} #{@method[:start]} > #{line} > #{@method[:end]}"
  end


  def pry_puts(text)
    @command[:pry].output.puts text
  end

  def exit_from_method
    @pry_start_options[:exit_from_method] = true
    true
  end

end
end
