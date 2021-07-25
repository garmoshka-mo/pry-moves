class PryMoves::Formatter

  attr_accessor :colorize

  def initialize colorize = true
    @colorize = colorize
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
          when :req   then "#{name} ="
          when :key   then "#{name}:"
          when :opt   then "#{name}=?"
          when :rest  then "*#{name}"
          when :block then "&#{name}"
          else '?'
        end
        show_value ? "#{name} #{value}" : name
      end
      "#{meth_obj.name}(#{args.join(', ')})"
    end
  end

  def format_arg binding, arg_name
    arg = binding.eval(arg_name.to_s)
    format_obj arg
  end

  def first_line str
    str.split("\n").first
  end

  def cut_string str
    str.length > 50 ? "#{str.first 50}..." : str
  end

  PATH_TRASH = defined?(Rails) ? Rails.root.to_s : Dir.pwd

  def shorten_path(path)
    path.gsub( /^#{PATH_TRASH}\//, '')
  end

  def format_obj(obj)
    if obj.is_a? String
      format_obj2 cut_string first_line obj
    else
      first_line format_obj2 obj
    end
  end

  def format_obj2(obj)
    if @colorize
      PryMoves::Painter.colorize obj
    else
      i = obj.inspect
      i.start_with?('#<') ? obj.class.to_s : i
    end
  end

end