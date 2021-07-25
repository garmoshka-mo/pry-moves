class PryMoves::Iterate < PryMoves::TraceCommand

  def init(binding_)
    @iteration_start_line = binding_.eval('__LINE__')
    @caller_digest = frame_digest(binding_)
  end

  def trace(event, file, line, method, binding_)
    return true if event == 'return' and
      @method.within?(file, line)

    # промотка итерации -
    # попасть на ту же или предыдущую строку или выйти из дайджеста
    # будучи в том же методе
    event == 'line' and @call_depth == 0 and
      @method.within?(file, line) and
      (line <= @iteration_start_line or
        @caller_digest != current_frame_digest
      )
  end

end
