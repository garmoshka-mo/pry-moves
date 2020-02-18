class PryMoves::Goto < PryMoves::TraceCommand

  def init
    @goto_line = @command[:param].to_i
  end

  def trace(event, file, line, method, binding_)
    event == 'line' && @goto_line == line and @method[:file] == file
  end

end
