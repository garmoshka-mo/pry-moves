require 'pry' unless defined? Pry

module PryMoves
class PryWrapper
  def initialize(pry_start_options = {})
    @pry_start_options = pry_start_options   # Options to use for Pry.start
  end

  def run(&block)
    PryMoves.lock

    return_value = nil
    PryMoves.is_open = true
    @command = catch(:breakout_nav) do      # Coordinates with PryMoves::Commands
      return_value = yield
      nil    # Nothing thrown == no navigational command
    end
    PryMoves.is_open = false

    if @command
      trace_command
    else
      PryMoves.semaphore.unlock
      if @pry_start_options[:pry_remote] && PryMoves.current_remote_server
        PryMoves.current_remote_server.teardown
      end
    end

    return_value
  end

  private

  def trace_command
    if @command[:action] == :debug
      wrap_debug
    else
      start_tracing
    end
  end

  def wrap_debug
    #puts "##wrap debug"
    #puts "CALLER:\n#{caller.join "\n"}\n"
    #      Thread.abort_on_exception=true
    $debug_mode = true
    Thread.new do
      #@command[:binding].eval 'puts "###########"'
      start_tracing
      @command[:binding].eval @command[:param]
    end.join
    $debug_mode = false
  end

  def start_tracing
    @tracer = PryMoves::Tracer.new @command, @pry_start_options
    @tracer.trace
  end

end
end