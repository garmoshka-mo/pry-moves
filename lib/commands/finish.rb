class PryMoves::Finish < PryMoves::TraceCommand

  def init
    @method_to_finish = @method
    @block_to_finish =
      (@binding_.frame_type == :block) &&
        frame_digest(@binding_)
  end

  def trace(event, file, line, method, binding_)
    return if @recursion_level >= 0 and not event == 'line'
    if @recursion_level < 0 or @method_to_finish != @method
      if redirect_step?(binding_)
        @action = :step
        return false
      end
      exit_from_method if event == 'return'
      return true
    end

    # for finishing blocks inside current method
    if @block_to_finish
      @recursion_level == 0 and
        within_current_method?(file, line) and
        @block_to_finish != current_frame_digest
    end
  end

end
