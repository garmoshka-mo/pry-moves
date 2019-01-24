require 'fileutils'

class PryMoves::Backtrace

  class << self
    def lines_count; @lines_count || 5; end
    def lines_count=(f); @lines_count = f; end

    def filter
      @filter || /(\/gems\/|\/rubygems\/|\/bin\/|\/lib\/ruby\/)/
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

  def run_command(param, param2)
    if param.is_a?(String) and (match = param.match /^>(.*)/)
      suffix = match[1].size > 0 ? match[1] : param2
      write_to_file build, suffix
    else
      @colorize = true
      if param.is_a? String and param.match /\d+/
        param = param.to_i
      end
      @lines_count = param || PryMoves::Backtrace::lines_count
      @pry.output.puts build
    end
  end

  private

  def build
    result = []
    show_vapid = %w(+ all hidden vapid).include? @lines_count
    stack = stack_bindings(show_vapid)
              .reverse.reject do |binding|
                binding.eval('__FILE__').match self.class::filter
              end

    if @lines_count.is_a?(Numeric) and stack.count > @lines_count
      result << "Latest #{@lines_count} lines: (`bt all` for full tracing)"
      stack = stack.last(@lines_count)
    end

    build_result stack, result
  end

  def build_result(stack, result)
    current_object = nil
    stack.each do |binding|
      obj = binding.eval 'self'
      if current_object != obj
        result << "#{format_obj(obj)}:"
        current_object = obj
      end

      result << build_line(binding)
    end
    result
  end

  def format_obj(obj)
    if @colorize
      PryMoves::Painter.colorize obj
    else
      obj.inspect
    end
  end

  def build_line(binding)
    file = "#{binding.eval('__FILE__')}"
    file.gsub!( /^#{Rails.root.to_s}/, '') if defined? Rails

    signature = PryMoves::Helpers.method_signature binding
    signature = ":#{binding.frame_type}" if !signature or signature.length < 1

    indent = frame_manager.current_frame == binding ?
        ' => ': '    '

    line = binding.eval('__LINE__')
    "#{indent}#{file}:#{line} #{signature}"
  end

  def frame_manager
    PryStackExplorer.frame_manager(@pry)
  end

  def stack_bindings(vapid_frames)
    frame_manager.filter_bindings vapid_frames: vapid_frames
  end

  def write_to_file(lines, file_suffix)
    log_path = log_path file_suffix
    File.write log_path, lines.join("\n")
    puts "Backtrace logged to #{log_path}"
  end

  def log_path(file_suffix)
    root = defined?(Rails) ? Rails.root.to_s : '.'
    root += '/log'
    FileUtils.mkdir_p root
    "#{root}/backtrace_#{file_suffix}.log"
  end

end