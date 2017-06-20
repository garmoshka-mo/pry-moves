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
        if defined? Rails
          line.gsub( /^#{Rails.root.to_s}/, '')
        else
          line
        end
      end
    end
  end

  def initialize(binding)
     @binding = binding
  end

  def build
    lines = @binding.eval 'caller'
    lines.reverse.reject do |line|
        line.match self.class::filter
      end.map &self.class::formatter
  end

  def run_command(param)
    if param.is_a?(String) and (match = param.match /^>(.*)/)
      write_to_file build, match[1]
    else
      puts cut(build, param || PryMoves::Backtrace::lines_count)
    end
  end

  private

  def cut(lines, lines_count = :all)
    if (lines_count.is_a?(Numeric) or lines_count.match /\d+/) and
        lines.count > lines_count.to_i
      ["Latest #{lines_count} lines: (`bt all` for full tracing)"] +
        lines.last(lines_count.to_i)
    else
      lines
    end
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