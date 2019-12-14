module PryMoves::TraceCommands

  private

  def trace_next(event, file, line, method, binding_)
    traced_method_exit = (@recursion_level < 0 and %w(line call).include? event)
    if traced_method_exit
      # Set new traced method, because we left previous one
      set_traced_method binding_
      throw :skip if event == 'call'
    end

    if @recursion_level == 0 and
      within_current_method?(file, line)

      if event == 'line'
        if @stay_at_frame
          return (
            @stay_at_frame == current_frame_digest or
            @c_stack_level < 0
          )
        else
          return true
        end
      end

       exit_from_method if event == 'return' and
         method == @method[:name] and before_end?(line)
    end
  end

  def trace_finish(event, file, line, method, binding_)
    return if @recursion_level >= 0 and not event == 'line'
    if @recursion_level < 0 or @method_to_finish != @method
      if redirect_step?(binding_)
        @action = :step
        return false
      end
      return true
    end

    # for finishing blocks inside current method
    if @block_to_finish
      @recursion_level == 0 and
        within_current_method?(file, line) and
        @block_to_finish != current_frame_digest
    end
  end

  def trace_debug(event, file, line, method, binding_)
    return unless event == 'line'
    if @first_line_skipped
      true
    else
      @first_line_skipped = true
      false
    end
  end

  def trace_iterate(event, file, line, method, binding_)
    return exit_from_method if event == 'return' and
      within_current_method?(file, line)

    # промотка итерации -
    # попасть на ту же или предыдущую строку или выйти из дайджеста
    # будучи в том же методе
    event == 'line' and @recursion_level == 0 and
      within_current_method?(file, line) and
      (line <= @iteration_start_line or
        @caller_digest != current_frame_digest
      )
  end

  def trace_goto(event, file, line, method, binding_)
    event == 'line' && @goto_line == line and @method[:file] == file
  end

end