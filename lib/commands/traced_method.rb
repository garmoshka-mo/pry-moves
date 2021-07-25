class PryMoves::TracedMethod < Hash

  @@last = nil
  def self.last
    @@last
  end

  def initialize(binding_)
    super()

    method = find_method_definition binding_
    if method
      source = method.source_location
      set_method({
        file: source[0],
        start: source[1],
        name: method.name,
        end: (source[1] + method.source.count("\n") - 1)
      })
    else
      file, line = binding_.source_location
      set_method({file: file})
    end
  end

  def within?(file, line, id = nil)
    return unless self[:file] == file
    return unless self[:start].nil? or
      line.between?(self[:start], self[:end])
    return unless id.nil? or self[:name] == id # fix for bug in traced_method: return for dynamic methods has line number inside of caller

    true
  end

  def binding_inside?(binding)
    within? *binding.eval('[__FILE__, __LINE__, __method__]')
  end

  def before_end?(line)
    self[:end] and line < self[:end]
  end

  private

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
    merge! method
    @@last = self
  end

end