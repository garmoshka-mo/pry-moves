module PryMoves::TraceCommands

  private

  def trace_step(event, file, line, binding_)
    return unless event == 'line'

    if @step_in_everywhere
      true
    elsif @step_into_funcs

      if @recursion_level < 0
        pry_puts "⚠️  Unable to find function with name #{@step_into_funcs.join(',')}"
        return true
      end

      method = binding_.eval('__callee__').to_s
      return false unless method_matches?(method)

      return false if redirect_step_into? binding_

      (not @caller_digest or # if we want to step-in only into straight descendant
        @caller_digest == frame_digest(binding_.of_caller(3 + 1)))

    elsif redirect_step_into? binding_
      false
    else
      not binding_.local_variable_defined? :hide_from_stack
    end
  end

  def trace_next(event, file, line, binding_)
    traced_method_exit = (@recursion_level < 0 and %w(line call).include? event)
    if traced_method_exit
      # Set new traced method, because we left previous one
      set_traced_method binding_
      throw :skip if event == 'call'
    end

    if @recursion_level == 0 and
      within_current_method?(file, line)

      if event == 'line'
        return (
        not @stay_at_frame or
          @stay_at_frame == frame_digest(binding_.of_caller(3))
        )
      end

      if event == 'return' and before_end?(line)
        @pry_start_options[:exit_from_method] = true
        true
      end
    end
  end

  def trace_finish(event, file, line, binding_)
    return unless event == 'line'
    if @recursion_level < 0 or @method_to_finish != @method
      if redirect_step_into?(binding_)
        @action = :step
        return false
      end
      return true
    end

    # for finishing blocks inside current method
    if @block_to_finish
      @recursion_level == 0 and
        within_current_method?(file, line) and
        @block_to_finish != frame_digest(binding_.of_caller(3))
    end
  end

  def trace_debug(event, file, line, binding_)
    return unless event == 'line'
    if @first_line_skipped
      true
    else
      @first_line_skipped = true
      false
    end
  end

  def trace_iteration(event, file, line, binding_)
    raise 'not implemented'
    # implementation:
    # 1) ставить метки там, где происходит сама итерация?
    # 2) можно догадываться по имени методов в стеке вверху: each / each_with_index
  end

end