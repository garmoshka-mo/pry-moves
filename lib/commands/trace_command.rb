require 'digest'
require 'pry' unless defined? Pry

module PryMoves
class TraceCommand

  include PryMoves::TraceHelpers

  def self.trace(command, pry_start_options, &callback)
    cls = command[:action].to_s.split('_').collect(&:capitalize).join
    cls = Object.const_get "PryMoves::#{cls}"
    cls.new command, pry_start_options, &callback
  end

  def initialize(command, pry_start_options, &callback)
    @command = command
    @pry_start_options = pry_start_options
    @pry_start_options[:pry_moves_loop] = true
    @callback = callback
    @call_depth = 0
    @c_stack_level = 0

    binding_ = @command[:binding] # =Command.target - more rich, contains required @iseq
    unless binding_.instance_variable_get('@iseq')
      binding_ = PryMoves::BindingsStack.new(@pry_start_options).initial_frame
    end
    @method = PryMoves::TracedMethod.new binding_

    if @pry_start_options.delete :exit_from_method
      @on_exit_from_method = true
      @call_depth -= 1
    end
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

  def tracing_func(event, file, line, method, binding_, klass)

    # Ignore traces inside pry-moves code
    return if file && TRACE_IGNORE_FILES.include?(File.expand_path(file))
    return unless binding_ # ignore strange cases

    # for cases when currently traced method called more times recursively
    if event == "call" and traced_method?(file, line, method, binding_)
      @call_depth += 1
    elsif %w(c-call c-return).include?(event)
      # todo: может быть, c-return тоже правильнее делать после trace
      delta = event == 'c-call' ? 1 : -1
      @c_stack_level += delta
    end

    printf "👟 %8s %s:%-2d %10s %8s dep:#{@call_depth} c_st:#{@c_stack_level}\n", event, file, line, method, klass if PryMoves.trace # TRACE_MOVES=1

    if trace event, file, line, method, binding_
      @pry_start_options[:exit_from_method] = true if event == 'return'
      stop_tracing
      @callback.call binding_
    elsif event == "return" and traced_method?(file, line, method, binding_)
      @call_depth -= 1
    end
  rescue => err
    puts err.backtrace.reverse
    puts "PryMoves Tracing error: #{err}".red
  end

  def traced_method?(file, line, method, binding_)
    @method.within?(file, line, method)
  end

end
end
