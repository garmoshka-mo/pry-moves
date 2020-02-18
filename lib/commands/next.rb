class PryMoves::Next < PryMoves::TraceCommand

  def init
    @start_line = @binding_.eval('__LINE__')
    @start_digest = frame_digest(@binding_)
    if @command[:param] == 'blockless'
      @stay_at_frame = @start_digest
    end
  end

  def trace(event, file, line, method, binding_)
    traced_method_exit = (@call_depth < 0 and %w(line call).include? event)
    if traced_method_exit
      # Set new traced method, because we left previous one
      set_traced_method
      throw :skip if event == 'call'
    end

    if @call_depth == 0 and
      within_current_method?(file, line)

      if event == 'line'
        if @stay_at_frame
          return (
          @stay_at_frame == current_frame_digest or
            @c_stack_level < 0
          )
        elsif @start_line != line or @start_digest == current_frame_digest
          return true
        end
      end

      exit_from_method if event == 'return' and
        method == @method[:name] and before_end?(line)
    end
  end

end
