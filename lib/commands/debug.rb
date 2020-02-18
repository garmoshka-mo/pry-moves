class PryMoves::Debug < PryMoves::TraceCommand

  def init
    #
  end

  def trace(event, file, line, method, binding_)
    return unless event == 'line'
    if @first_line_skipped
      true
    else
      @first_line_skipped = true
      false
    end
  end

end
