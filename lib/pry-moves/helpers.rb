module PryMoves::Helpers

  extend self

  # @return [String] Signature for the method object in Class#method format.
  def method_signature_with_owner(binding)
    meth = binding.eval('__method__')
    meth_obj = meth ? Pry::Method.from_binding(binding) : nil
    if !meth_obj
      ""
    elsif meth_obj.undefined?
      "#{meth_obj.name_with_owner}(UNKNOWN) (undefined method)"
    else
      args = meth_obj.parameters.inject([]) do |arr, (type, name)|
        name ||= (type == :block ? 'block' : "arg#{arr.size + 1}")
        arr << case type
                 when :req   then name.to_s
                 when :opt   then "#{name}=?"
                 when :rest  then "*#{name}"
                 when :block then "&#{name}"
                 else '?'
               end
      end
      "#{meth_obj.name_with_owner}(#{args.join(', ')})"
    end
  end

  def method_signature(binding)
    meth = binding.eval('__method__')
    meth_obj = meth ? Pry::Method.from_binding(binding) : nil
    if !meth_obj
      ""
    elsif meth_obj.undefined?
      "#{meth_obj.name}(UNKNOWN) (undefined method)"
    else
      args = meth_obj.parameters.inject([]) do |arr, (type, name)|
        name ||= (type == :block ? 'block' : "arg#{arr.size + 1}")
        arr << case type
               when :req   then name.to_s
               when :opt   then "#{name}=?"
               when :rest  then "*#{name}"
               when :block then "&#{name}"
               else '?'
               end
      end
      "#{meth_obj.name}(#{args.join(', ')})"
    end
  end

end