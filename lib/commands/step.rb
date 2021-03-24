class PryMoves::Step < PryMoves::TraceCommand

  def init(binding_)
    @step_into_funcs = nil
    @start_line = binding_.eval('__LINE__')
    @caller_digest = frame_digest(binding_)
    func = @command[:param]
    redirect_step? binding_ # set @step_into_funcs from initial binding
    if func == '+'
      @step_in_everywhere = true
    elsif func
      @find_straight_descendant = true
      @step_into_funcs = [func]
      @step_into_funcs << '=initialize' if func == 'new' or func == '=new'
    end
  end

  def trace(event, file, line, method, binding_)
    if binding_.local_variable_defined? :pry_moves_skip
      finish_cmd = {binding: binding_}
      PryMoves::Finish.new finish_cmd, @pry_start_options do |binding|
        start_tracing
      end
      return
    end

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
      if @call_depth < 0
        PryMoves.messages << "⚠️  Unable to find function with name #{@step_into_funcs.join(',')}"
        return true
      end

      return false if keep_search_method? binding_
    elsif redirect_step? binding_
      return false
    elsif binding_.local_variable_defined? :hide_from_stack and
          not @method.within?(file, line, method)
      return false
    end

    true
  end

  def keep_search_method? binding_
    method = binding_.eval('__callee__').to_s
    return true unless method_matches?(method)

    return true if @find_straight_descendant &&
      # if we want to step-in only into straight descendant
      @caller_digest != current_frame_digest(upward: 1 + 1) # 1 for getting parent and 1 for 'def keep_search_method?'
    @find_straight_descendant = false

    return true if redirect_step? binding_
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

end
