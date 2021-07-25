class PryMoves::Goto < PryMoves::TraceCommand

  def init(binding_)
    @goto_line = @command[:param].to_i
  end

  def trace(event, file, line, method, binding_)
    if @call_depth < 0 or
        @call_depth == 0 and event == 'return' and @method.within?(file, line)
      PryMoves.messages << "⚠️  Unable to reach line #{@goto_line} in current frame"
      return true
    end

    event == 'line' && @goto_line == line and
      @method[:file] == file and
      @call_depth == 0
  end

end
