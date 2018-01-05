require 'pry' unless defined? Pry

module PryMoves
class PryWrapper
  def initialize(binding_, pry_start_options = {})
    @init_binding = binding_
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
      PryMoves.unlock
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
    parent_thread = Thread.current
    Thread.new do

      # copy non-pry thread's properties
      parent_thread.keys.select do |k|
        !k.to_s.include?('pry')
      end.each do |k|
        Thread.current[k] = parent_thread[k]
      end

      Thread.current[:pry_moves_debug] = true
      #@command[:binding].eval 'puts "###########"'
      start_tracing
      begin
        @command[:binding].eval @command[:param]
      rescue => e
        Thread.current.set_trace_func nil
        puts e
      end
    end.join
    binding_ = @last_runtime_binding || @init_binding
    Pry.start(binding_, @pry_start_options)
  end

  def start_tracing
    @last_runtime_binding = @command[:binding]
    @tracer = PryMoves::Tracer.new @command, @pry_start_options
    @tracer.trace
  end

end
end