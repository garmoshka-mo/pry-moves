require 'digest'
require 'pry' unless defined? Pry

module PryMoves
class TraceCommand

  include PryMoves::TracedMethod

  def self.trace(command, pry_start_options)
    cls = command[:action].to_s.split('_').collect(&:capitalize).join
    cls = Object.const_get "PryMoves::#{cls}"
    cls.new command, pry_start_options
  end

  def initialize(command, pry_start_options)
    @command = command
    @pry_start_options = pry_start_options
    @pry_start_options[:pry_moves_loop] = true

    @action = @command[:action]
    #puts "COMMAND: #{@action}"
    binding_ = @command[:binding] # =Command.target - more rich, contains required @iseq
    set_traced_method binding_

    @call_depth -= 1 if @pry_start_options.delete :exit_from_method
    @pry_start_options.delete :initial_frame

    init binding_
    start_tracing
  end

  def start_tracing
    #puts "##trace_obj #{trace_obj}"
    Pry.config.disable_breakpoints = true
    trace_obj.set_trace_func method(:tracing_func).to_proc
  end

  def stop_tracing
    trace_obj.set_trace_func nil
    Pry.config.disable_breakpoints = false
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

  def current_frame_digest(upward: 0)
    # binding_ from tracing_func doesn't have @iseq,
    # therefore binding should  be re-retrieved using 'binding_of_caller' lib
    frame_digest(binding.of_caller(4 + upward))
  end

  def frame_digest(binding_)
    #puts "frame_digest for: #{binding_.eval '__callee__'}"
    Digest::MD5.hexdigest binding_.instance_variable_get('@iseq').disasm
  end

  def tracing_func(event, file, line, id, binding_, klass)
    printf "👟 %8s %s:%-2d %10s %8s dep:#{@call_depth} c_st:#{@c_stack_level}\n", event, file, line, id, klass if PryMoves.trace

    # Ignore traces inside pry-moves code
    return if file && TRACE_IGNORE_FILES.include?(File.expand_path(file))
    return unless binding_ # ignore strange cases

    catch(:skip) do
      if trace event, file, line, id, binding_
        stop_tracing
        Pry.start(binding_, @pry_start_options)

        # for cases when currently traced method called more times recursively
      elsif %w(call return).include?(event) and within_current_method?(file, line) and
        @method[:name] == id # fix for bug in traced_method: return for dynamic methods has line number inside of caller
        delta = event == 'call' ? 1 : -1
        #puts "recursion #{event}: #{delta}; changed: #{@call_depth} => #{@call_depth + delta}"
        @call_depth += delta
      elsif %w(c-call c-return).include?(event)
        delta = event == 'c-call' ? 1 : -1
        @c_stack_level += delta
      end
    end
  end

  def redirect_step?(binding_)
    return false unless binding_.local_variable_defined? :debug_redirect

    debug_redirect = binding_.local_variable_get(:debug_redirect)
    @step_into_funcs = [debug_redirect.to_s] if debug_redirect
    true
  end

  def debug_info(file, line, id)
    puts "📽  Action:#{@action}; recur:#{@call_depth}; #{@method[:file]}:#{file}"
    puts "#{id} #{@method[:start]} > #{line} > #{@method[:end]}"
  end

  def exit_from_method
    @pry_start_options[:exit_from_method] = true
    true
  end

end
end
