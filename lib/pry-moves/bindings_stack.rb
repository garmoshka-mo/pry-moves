class PryMoves::BindingsStack < Array

  def initialize
    @vapid_bindings = []
    bindings = binding.callers # binding_of_caller has bug and always returns callers of current binding,
      # no matter at which binding method is called. So no need to pass here binding
    pre_callers = Thread.current[:pre_callers]
    bindings = bindings + pre_callers if pre_callers
    concat remove_internal_frames(bindings)
    mark_vapid_frames
  end

  def initial_frame_index
    index{|b| not vapid? b} || 0
  end
  def initial_frame
    find{|b| not vapid? b}
  end

  def filter_bindings(vapid_frames: false)
    self.reject do |binding|
      !vapid_frames and vapid? binding
    end
  end

  def vapid?(binding)
    @vapid_bindings.include? binding
  end

  private

  def mark_vapid_frames
    stepped_out = false
    actual_file, actual_method = nil, nil

    each do |binding|
      file, method, obj = binding.eval("[__FILE__, __method__, self]")

      if file.match PryMoves::Backtrace::filter
        @vapid_bindings << binding
      elsif stepped_out
        if actual_file == file and actual_method == method
          stepped_out = false
        else
          @vapid_bindings << binding
        end
      elsif binding.frame_type == :block
        stepped_out = true
        actual_file = file
        actual_method = method
      elsif obj and method and obj.method(method).source.strip.match /^delegate\s/
        @vapid_bindings << binding
      end

      if binding.local_variable_defined? :hide_from_stack
        @vapid_bindings << binding
      end
    end
  end

  # remove internal frames related to setting up the session
  def remove_internal_frames(bindings)
    i = top_internal_frame_index(bindings)
    # DEBUG:
    #bindings.each_with_index do |b, index|
    #  puts "#{index}: #{b.eval("self.class")} #{b.eval("__method__")}"
    #end
    #puts "FOUND top internal frame: #{bindings.size} => #{i}"

    bindings.drop i+1
  end

  def top_internal_frame_index(bindings)
    bindings.rindex do |b|
      if b.frame_type == :method
        self_, method = b.eval("self"), b.eval("__method__")
        self_.equal?(Pry) && method == :start ||
          self_.class == Binding && method == :pry ||
          self_.class == PryMoves::Tracer && method == :tracing_func
      end
    end
  end

end