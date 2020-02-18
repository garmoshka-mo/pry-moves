module PryMoves::TracedMethod

  private

  def set_traced_method
    @call_depth = 0
    @c_stack_level = 0
    @stay_at_frame = nil # reset tracked digest

    method = find_method_definition @binding_
    if method
      source = method.source_location
      set_method({
                   file: source[0],
                   start: source[1],
                   name: method.name,
                   end: (source[1] + method.source.count("\n") - 1)
                 })
    else
      set_method({file: @binding_.eval('__FILE__')})
    end
  end

  def find_method_definition(binding)
    method_name, obj, file =
      binding.eval '[__method__, self, __FILE__]'
    return unless method_name

    method = obj.method(method_name)
    return method if method.source_location[0] == file

    # If found file was different - search definition at superclasses:
    obj.class.ancestors.each do |cls|
      if cls.instance_methods(false).include? method_name
        method = cls.instance_method method_name
        return method if method.source_location[0] == file
      end
    end

    PryMoves.messages << "⚠️  Unable to find definition for method #{method_name} in #{obj}"

    nil
  end

  def set_method(method)
    #puts "set_traced_method #{method}"
    @method = method
  end

  def within_current_method?(file, line)
    @method[:file] == file and (
    @method[:start].nil? or
      line.between?(@method[:start], @method[:end])
    )
  end

  def before_end?(line)
    @method[:end] and line < @method[:end]
  end

end