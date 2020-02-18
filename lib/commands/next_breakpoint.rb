class PryMoves::NextBreakpoint < PryMoves::TraceCommand

  def init
    @reach_digest = frame_digest(@binding_)
  end

  def trace(event, file, line, method, binding_)
    if @reach_digest
      if @reach_digest == current_frame_digest
        @reach_digest = nil
      else
        return
      end
    end

    if method.to_s.include? "debug"
      @pry_start_options[:initial_frame] = 1
      true
    end
  end

end
