require 'pry' unless defined? Pry

module PryNav
class Tracer
  def initialize(pry_start_options = {}, &block)
    @frames = 0                              # Traced stack frame level
    @pry_start_options = pry_start_options   # Options to use for Pry.start
  end

  def run(&block)
    # For performance, disable any tracers while in the console.
    # Unfortunately doesn't work in 1.9.2 because of
    # http://redmine.ruby-lang.org/issues/3921. Works fine in 1.8.7 and 1.9.3.
    stop_tracing unless RUBY_VERSION == '1.9.2'

    return_value = nil
    command = catch(:breakout_nav) do      # Coordinates with PryNav::Commands
      return_value = yield
      {}    # Nothing thrown == no navigational command
    end

    # Adjust tracer based on command
    if process_command(command)
      start_tracing
    else
      stop_tracing if RUBY_VERSION == '1.9.2'
      if @pry_start_options[:pry_remote] && PryNav.current_remote_server
        PryNav.current_remote_server.teardown
      end
    end

    return_value
  end

  def start_tracing
    set_trace_func method(:tracer).to_proc
  end

  def stop_tracing
    set_trace_func nil
  end

  def process_command(command = {})
    @times = (command[:times] || 1).to_i
    @times = 1 if @times <= 0

    set_traced_method command[:binding]

    @action = command[:action]
    [:step, :next, :finish].include? @action
  end


  private

  def set_traced_method(binding)
    @recursion_level = 0

    method = binding.eval 'method(__method__) if __method__'
    return @method = {file: binding.eval('__FILE__')} unless method

    source = method.source_location
    @method = {
        file: source[0],
        start: source[1],
        end: (source[1] + method.source.count("\n") - 1)
        #thread: binding.eval 'Thread.current' # todo: Нужна проверка по треду?
    }
  end

  def tracer(event, file, line, id, binding_, klass)
    # Ignore traces inside pry-nav code
    return if file && TRACE_IGNORE_FILES.include?(File.expand_path(file))

    traced_method_exit = (@recursion_level < 0 and %w(line call).include? event)
    set_traced_method binding_ if traced_method_exit

    case event
      when 'line'
        Pry.start(binding_, @pry_start_options) if break_here?(file, line, traced_method_exit)
      when 'call', 'return'
        recursion_step event if within_current_method?(file, line)
    end
  end

  def break_here?(file, line, traced_method_exit)
    case @action
      when :step
        true
      when :finish
        traced_method_exit
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
    @recursion_level += event == 'call' ? 1 : -1
  end

end
end