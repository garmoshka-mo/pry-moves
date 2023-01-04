require 'fileutils'

class PryMoves::Backtrace

  FILTERS = %w[/gems/ /rubygems/ /bin/ /lib/ruby/]
  FILTERS << File.expand_path('..', __dir__)
  @@backtrace = nil

  class << self
    attr_accessor :trim_path

    def filter
      @filter ||= Regexp.new FILTERS.join("|")
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
    @builder = PryMoves::BacktraceBuilder.new frame_manager
  end

  def run_command(param, param2)
    if param == 'save' || param == 'diff' && @@backtrace.nil?
      @@hard_saved = param == 'save'
      @builder.filter = 'hidden'
      @builder.lines_numbers = false
      @@backtrace = @builder.build_backtrace
      @pry.output.puts "💾 Backtrace saved (#{@@backtrace.count} lines)"
    elsif param == 'diff'
      @builder.filter = 'hidden'
      @builder.lines_numbers = false
      diff
      @@backtrace = nil unless @@hard_saved
    elsif param and (match = param.match /^::(\w*)/)
      @builder.colorize = true
      @pry.output.puts @builder.objects_of_class match[1]
    elsif param.is_a?(String) and (match = param.match /^>(.*)/)
      suffix = match[1].size > 0 ? match[1] : param2
      write_to_file @builder.build_backtrace, suffix
    elsif param and param.match /\d+/
      index = param.to_i
      frame_manager.goto_index index
    else
      print_backtrace param
    end
  end

  private

  def print_backtrace filter
    @builder.colorize = true
    @builder.filter = filter if filter.is_a? String
    @pry.output.puts @builder.build_backtrace
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

  def diff
    return STDERR.puts "No backtrace saved. Use `bt save` first".yellow unless defined? @@backtrace

    @pry.output.puts Diffy.diff(
      @@backtrace.join("\n"),
      @builder.build_backtrace.join("\n")
    )
  end

end

Pry.config.exception_handler = proc do |output, exception, _|

  def print_error message, exception, output
    output.puts message.red
    exception.backtrace.reject! {|l| l.match /sugar\.rb/}
    exception.backtrace.first(3).each { output.puts _1.white }
  end

  if Pry::UserError === exception && SyntaxError === exception
    output.puts "SyntaxError: #{exception.message.sub(/.*syntax error, */m, '')}"
  else

    print_error "#{exception.class}: #{exception.message}", exception, output

    if exception.respond_to? :cause
      cause = exception.cause
      while cause
        print_error "Caused by #{cause.class}: #{cause}\n", exception, output
        cause = cause.cause
      end
    end
  end

end
