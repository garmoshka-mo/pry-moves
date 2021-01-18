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
        if name
          value = format_arg binding, name.to_s
          show_value = true
        else
          name = (type == :block ? 'block' : "arg#{i + 1}")
        end
        name = case type
               when :req   then name.to_s
               when :opt   then "#{name}=?"
               when :rest  then "*#{name}"
               when :block then "&#{name}"
               else '?'
               end
        show_value ? "#{name}: #{value}" : name
      end
      "#{meth_obj.name}(#{args.join(', ')})"
    end
  end

  def format_arg binding, arg_name
    arg = binding.eval(arg_name.to_s)
    if arg.is_a? String
      format_obj cut_string arg
    else
      cut_string format_obj arg
    end
  end

  def cut_string str
    str = str.split("\n").first
    str.length > 50 ? "#{str.first 50}..." : str
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