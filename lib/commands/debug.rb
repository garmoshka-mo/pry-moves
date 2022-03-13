class PryMoves::Debug < PryMoves::TraceCommand

  def init(binding_)
    #
  end

  def trace(event, file, line, method, binding_)
    return if event != 'line' or @cancel_debug
    if @first_line_skipped
      if binding_.local_variable_defined?(:pry_cancel_debug)
        @cancel_debug = true
        return
      end
      true
    else
      @first_line_skipped = true
      false
    end
  end

end
