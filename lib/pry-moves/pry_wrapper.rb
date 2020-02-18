require 'pry' unless defined? Pry

module PryMoves
class PryWrapper
  def initialize(binding_, pry_start_options = {})
    @init_binding = binding_
    @pry_start_options = pry_start_options   # Options to use for Pry.start
  end

  def run(&block)
    PryMoves.lock

    if not @pry_start_options[:pry_moves_loop] and
        @init_binding.local_variable_defined? :debug_redirect
      debug_redirect = @init_binding.local_variable_get(:debug_redirect)
      PryMoves.messages << "⏩ redirected to #{debug_redirect}"
      @command = {action: :step,
        binding: PryMoves::BindingsStack.new.initial_frame}
    else
      start_pry(&block)
    end

    if @command
      trace_command
    else
      PryMoves.unlock
      if @pry_start_options[:pry_remote] && PryMoves.current_remote_server
        PryMoves.current_remote_server.teardown
      end
    end

    @return_value
  end

  private

  def start_pry
    Pry.config.marker = "⛔️" if @pry_start_options[:exit_from_method]
    PryMoves.is_open = true

    @command = catch(:breakout_nav) do      # Coordinates with PryMoves::Commands
      @return_value = yield
      nil    # Nothing thrown == no navigational command
    end

    PryMoves.is_open = false
    Pry.config.marker = "=>"
  end

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
      tracer = start_tracing
      begin
        @command[:binding].eval @command[:param]
      rescue StandardError, SyntaxError => e
        Thread.current.set_trace_func nil
        puts "❌️ #{e}"
      end
      tracer.stop_tracing
    end.join
    binding_ = @last_runtime_binding || @init_binding
    Pry.start(binding_, @pry_start_options)
  end

  def start_tracing
    @last_runtime_binding = @command[:binding]
    PryMoves::TraceCommand.trace @command, @pry_start_options
  end

end
end