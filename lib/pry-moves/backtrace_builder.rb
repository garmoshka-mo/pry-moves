class PryMoves::BacktraceBuilder

  attr_writer :lines_numbers, :filter, :colorize

  def initialize frame_manager
    @frame_manager = frame_manager
    @filter = nil
    @colorize = false
    @lines_numbers = true
    @formatter = PryMoves::Formatter.new
  end

  def build_backtrace
    show_all = %w(a all).include?(@filter)
    show_vapid = %w(+ hidden vapid).include?(@filter) || show_all
    result = []
    current_object, vapid_count = nil, 0

    recursion = PryMoves::Recursion::Holder.new

    @frame_manager.bindings.reverse.each do |binding|
      next if !show_all and binding.eval('__FILE__').match PryMoves::Backtrace::filter

      if !show_vapid and binding.hidden
        vapid_count += 1
        next
      end

      if vapid_count > 0
        result << "👽  frames hidden: #{vapid_count}"
        vapid_count = 0
      end

      obj, debug_snapshot = binding.eval '[self, (debug_snapshot rescue nil)]'
      # Comparison of objects directly may raise exception
      if current_object.object_id != obj.object_id
        result << "#{debug_snapshot || @formatter.format_obj(obj)}"
        current_object = obj
      end

      file, line = binding.eval('[__FILE__, __LINE__]')
      recursion.track file, line, result.count, binding.index unless show_vapid
      result << build_line(binding, file, line)
    end

    # recursion.each { |t| t.apply result }

    result << "👽  frames hidden: #{vapid_count}" if vapid_count > 0

    result
  end

  def objects_of_class class_pattern
    result = []
    last_object = nil
    class_pattern.downcase!
    @frame_manager.bindings.reverse.each do |binding|
      obj = binding.eval 'self'
      next if !obj.class.to_s.downcase.include?(class_pattern) ||
        last_object.object_id == obj.object_id

      result << "#{line_num binding}#{@formatter.format_obj(obj)}"
      last_object = obj
    end
    result
  end

  private

  def line_num binding
    num = "#{binding.index}:".ljust(4, ' ')
    @colorize ? "\e[2;49;90m#{num}\e[0m" : num
  end

  def build_line(binding, file, line)
    file = @formatter.shorten_path "#{file}"

    signature = @formatter.method_signature binding
    signature = ":#{binding.frame_type}" if !signature or signature.length < 1

    indent = if @frame_manager.current_frame == binding
      '==> '
    elsif @lines_numbers
      line_num binding
    else
      '    '
    end

    "#{indent}#{file}:#{line} #{signature}"
  end

end