require 'pry' unless defined? Pry

module PryMoves
class PryWrapper
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
    command = catch(:breakout_nav) do      # Coordinates with PryMoves::Commands
      return_value = yield
      nil    # Nothing thrown == no navigational command
    end
    PryMoves.is_open = false

    if command
      @tracer = PryMoves::Tracer.new command, @pry_start_options
      @tracer.trace
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

  def stop_tracing
    @tracer.stop_tracing if @tracer
  end

end
end