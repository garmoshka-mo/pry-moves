require 'fileutils'

class PryMoves::Backtrace

  class << self

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

  def initialize(pry)
    @pry = pry
    @formatter = PryMoves::Formatter.new
  end

  def run_command(param, param2)
    if param.is_a?(String) and (match = param.match /^>(.*)/)
      suffix = match[1].size > 0 ? match[1] : param2
      @formatter.colorize = false
      write_to_file build, suffix
    elsif param and param.match /\d+/
      index = param.to_i
      frame_manager.goto_index index
    else
      print_backtrace param
    end
  end

  private

  def print_backtrace filter
    @colorize = true
    @lines_numbers = true
    @filter = filter if filter.is_a? String
    @pry.output.puts build
  end

  def build
    show_vapid = %w(+ a all hidden vapid).include?(@filter)
    show_all = %w(a all).include?(@filter)
    result = []
    current_object, vapid_count = nil, 0

    frame_manager.bindings.each_with_details do |binding, vapid|
      next if !show_all and binding.eval('__FILE__').match self.class::filter

      if !show_vapid and vapid
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
        result << "#{debug_snapshot || @formatter.format_obj(obj)}:"
        current_object = obj
      end

      result << build_line(binding)
    end

    result << "👽  frames hidden: #{vapid_count}" if vapid_count > 0

    result
  end

  def build_line(binding)
    file = @formatter.shorten_path "#{binding.eval('__FILE__')}"

    signature = @formatter.method_signature binding
    signature = ":#{binding.frame_type}" if !signature or signature.length < 1

    indent = if frame_manager.current_frame == binding
      '==> '
    elsif true #@lines_numbers
      s = "#{binding.index}:".ljust(4, ' ')
      @colorize ? "\e[2;49;90m#{s}\e[0m" : s
    else
      '    '
    end

    line = binding.eval('__LINE__')
    "#{indent}#{file}:#{line} #{signature}"
  end

  def frame_manager
    PryStackExplorer.frame_manager(@pry)
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

Pry.config.exception_handler = proc do |output, exception, _|
  if Pry::UserError === exception && SyntaxError === exception
    output.puts "SyntaxError: #{exception.message.sub(/.*syntax error, */m, '')}"
  else

    output.puts "#{exception.class}: #{exception.message}"
    exception.backtrace.reject! {|l| l.match /sugar\.rb/}
    output.puts "from #{exception.backtrace.first}"

    if exception.respond_to? :cause
      cause = exception.cause
      while cause
        output.puts "Caused by #{cause.class}: #{cause}\n"
        cause.backtrace.reject! {|l| l.match /sugar\.rb/}
        output.puts "from #{cause.backtrace.first}"
        cause = cause.cause
      end
    end
  end
end
