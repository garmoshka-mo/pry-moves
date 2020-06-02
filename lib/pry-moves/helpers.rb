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
      args = meth_obj.parameters.map.with_index do |(type, name), i|
        name ||= (type == :block ? 'block' : "arg#{i + 1}")
        value = format_obj binding.eval(name.to_s)
        name = case type
               when :req   then name.to_s
               when :opt   then "#{name}=?"
               when :rest  then "*#{name}"
               when :block then "&#{name}"
               else '?'
               end
        "#{name}: #{value}"
      end
      "#{meth_obj.name}(#{args.join(', ')})"
    end
  end

  PATH_TRASH = defined?(Rails) ? Rails.root.to_s : Dir.pwd

  def shorten_path(path)
    path.gsub( /^#{PATH_TRASH}\//, '')
  end

  def format_obj(obj)
    if @colorize
      PryMoves::Painter.colorize obj
    else
      i = obj.inspect
      i.start_with?('#<') ? obj.class.to_s : i
    end
  end

end