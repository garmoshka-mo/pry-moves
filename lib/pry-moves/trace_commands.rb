module PryMoves::TraceCommands

  private

  def trace_step(event, file, line, method, binding_)
    @const_missing_level ||= 0
    if method == :const_missing
      if event == 'call'
        @const_missing_level += 1
      elsif event == 'return'
        @const_missing_level -= 1
      end
    end
    return if @const_missing_level > 0

    return unless event == 'line'

    if @step_in_everywhere
      return true
    elsif @step_into_funcs

      if @recursion_level < 0
        pry_puts "⚠️  Unable to find function with name #{@step_into_funcs.join(',')}"
        return true
      end

      method = binding_.eval('__callee__').to_s
      return false unless method_matches?(method)

      return false if @find_straight_descendant &&
        # if we want to step-in only into straight descendant
        @caller_digest != current_frame_digest(upward: 1)
      @find_straight_descendant = false

      return false if redirect_step? binding_
    elsif redirect_step? binding_
      return false
    else
      return false if binding_.local_variable_defined? :hide_from_stack
    end

    true
  end

  def method_matches?(method)
    @step_into_funcs.any? do |pattern|
      if pattern.start_with? '='
        "=#{method}" == pattern
      else
        method.include? pattern
      end
    end
  end


  # command NEXT:

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
         method != :to_s and before_end?(line)
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