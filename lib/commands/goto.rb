class PryMoves::Goto < PryMoves::TraceCommand

  def init(binding_)
    @goto_line = @command[:param].to_i
  end

  def trace(event, file, line, method, binding_)
    if @call_depth < 0 or
        @call_depth == 0 and event == 'return' and within_current_method?(file, line)
      PryMoves.messages << "⚠️  Unable to reach line #{@goto_line} in current frame"
      exit_from_method if event == 'return'
      return true
    end

    event == 'line' && @goto_line == line and
      @method[:file] == file and
      @call_depth == 0
  end

end
