class PryMoves::BindingsStack < Array

  def initialize
    bindings = binding.callers # binding_of_caller has bug and always returns callers of current binding,
      # no matter at which binding method is called. So no need to pass here binding
    pre_callers = Thread.current[:pre_callers]
    bindings = bindings + pre_callers if pre_callers
    concat remove_internal_frames(bindings)
    set_indices
    mark_vapid_frames
  end

  def suggest_initial_frame_index
    m = PryMoves::TracedMethod.last
    return 0 if m and m.binding_inside?(first)
    index{|b| not b.hidden} || 0
  end
  def initial_frame
    find{|b| not b.hidden}
  end

  def each_with_details
    self.reverse.each do |binding|
      yield binding, binding.hidden
    end
  end

  private

  def set_indices
    reverse.each_with_index do |binding, index|
      binding.index = index
    end
  end

  def mark_vapid_frames
    stepped_out = false
    actual_file, actual_method = nil, nil

    # here calls checked in reverse order - from latest to parent:
    each do |binding|
      file, method, obj = binding.eval("[__FILE__, __method__, self]")

      if file.match PryMoves::Backtrace::filter
        binding.hidden = true
      elsif stepped_out
        if actual_file == file and actual_method == method or
            binding.local_variable_defined? :pry_moves_deferred_call
          stepped_out = false
        else
          binding.hidden = true
        end
      elsif binding.frame_type == :block
        stepped_out = true
        actual_file = file
        actual_method = method
      elsif obj and method and obj.method(method).source.strip.match /^delegate\s/
        binding.hidden = true
      end

      if binding.local_variable_defined? :hide_from_stack
        binding.hidden = true
      end
    end

    stack_tip_met = false
    stack_tips = PryMoves.stack_tips || []
    reverse.each do |binding|
      if binding.local_variable_defined?(:pry_moves_stack_tip) ||
          stack_tips.include?(binding.eval("__method__"))
        stack_tip_met = true
      end
      binding.hidden = true if stack_tip_met
    end
  end

  # remove internal frames related to setting up the session
  def remove_internal_frames(bindings)
    i = top_internal_frame_index(bindings)
    # DEBUG:
    #bindings.each_with_index do |b, index|
    #  puts "#{index}: #{b.eval("self.class")} #{b.eval("__method__")}"
    #end
    # puts "FOUND top internal frame in #{bindings.size} frames: [#{i}] #{bindings[i].ai}"

    bindings.drop i+1
  end

  def top_internal_frame_index(bindings)
    pry_moves_debug = Thread.current[:pry_moves_debug]
    bindings.rindex do |b|
      if not pry_moves_debug and b.frame_type == :eval
        true
      elsif b.frame_type == :method
        method, self_ = b.eval("[__method__, self, __FILE__]")

        self_.equal?(Pry) && method == :start ||
          self_.class == Binding && method == :pry ||
          self_.is_a?(PryMoves::TraceCommand) && method == :tracing_func ||
          b.local_variable_defined?(:pry_moves_stack_end)
      end
    end
  end

end