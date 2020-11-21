class PryMoves::Finish < PryMoves::TraceCommand

  def init(binding_)
    @method_to_finish = @method
    @block_to_finish = frame_digest(binding_) if binding_.frame_type == :block
  end

  def trace(event, file, line, method, binding_)
    return true if @on_exit_from_method
    return if @call_depth > 0 or event == 'c-return'

    if @call_depth < 0 and within_current_method?(file, line)
      @pry_start_options[:exit_from_method] = true
      return true
    end

    # for finishing blocks inside current method
    if @block_to_finish
      ((@call_depth == 0) ^ (event == 'return')) and
        within_current_method?(file, line) and
        @block_to_finish != current_frame_digest
    end
  end

end
