class PryMoves::NextBreakpoint < PryMoves::TraceCommand

  def init(binding_)
  end

  def trace(event, file, line, method, binding_)
    # this command will stuck in tracing when no breakpoint met (usually)
    PryMoves.messages << "⚠️  Command NextBreakpoint is not implemented"
    return true

    if binding_.local_variable_defined?(:pry_breakpoint) and
        binding_.local_variable_get(:pry_breakpoint)
      binding_.local_variable_set :pry_breakpoint, nil # reset breakpoint at visited method instance
      true
    end

    # if method.to_s.include? "debug"
    #   @pry_start_options[:initial_frame] = 1
    #   true
    # end
  end

end
