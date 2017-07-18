require 'fileutils'

class PryMoves::Backtrace

  class << self
    def lines_count; @lines_count || 5; end
    def lines_count=(f); @lines_count = f; end

    def filter
      @filter || /(\/gems\/|\/rubygems\/|\/bin\/|\/lib\/ruby\/|\/pry-moves\/)/
    end
    def filter=(f); @filter = f; end

    def format(&block)
      @formatter = block
    end

    def formatter
      @formatter || lambda do |line|
        # not used
      end
    end
  end

  def initialize(binding, pry)
     @binding, @pry = binding, pry
  end

  def build(lines_count = nil)
    result = []
    show_vapid = lines_count == 'all'
    stack = stack_bindings(show_vapid)
              .reverse.reject do |binding|
                binding.eval('__FILE__').match self.class::filter
              end

    if lines_count.is_a? String and lines_count.match /\d+/
      lines_count = lines_count.to_i
    end
    if lines_count.is_a?(Numeric) and stack.count > lines_count
      result << "Latest #{lines_count} lines: (`bt all` for full tracing)"
      stack = stack.last(lines_count)
    end

    build_result stack, result
  end

  def run_command(param)
    if param.is_a?(String) and (match = param.match /^>(.*)/)
      write_to_file build, match[1]
    else
      puts build(param || PryMoves::Backtrace::lines_count)
    end
  end

  private

  def build_result(stack, result)
    current_object = nil
    stack.each do |binding|
      obj = binding.eval 'self'
      if current_object != obj
        colored_obj = ""
        Pry::ColorPrinter.pp obj, colored_obj
        result << "#{colored_obj.chomp}:"
        current_object = obj
      end

      result << build_line(binding)
    end
    result
  end

  def build_line(binding)
    file = "#{binding.eval('__FILE__')}"
    file.gsub!( /^#{Rails.root.to_s}/, '') if defined? Rails

    signature = PryMoves::Helpers.method_signature_with_owner binding

    indent = frame_manager.current_frame == binding ?
        ' => ': '    '

    "#{indent}#{file}:#{binding.eval('__LINE__')} "+
      " #{signature} :#{binding.frame_type}"
  end

  def frame_manager
    PryStackExplorer.frame_manager(@pry)
  end

  def stack_bindings(vapid_frames)
    frame_manager.filter_bindings vapid_frames: vapid_frames
  end

  def write_to_file(lines, file_suffix)
    log_path = log_path file_suffix
    File.open(log_path, "w") do |f|
      f.puts lines
    end
    puts "Backtrace logged to #{log_path}"
  end

  def log_path(file_suffix)
    root = defined?(Rails) ? Rails.root.to_s : '.'
    root += '/log'
    FileUtils.mkdir_p root
    "#{root}/backtrace_#{file_suffix}.log"
  end

end