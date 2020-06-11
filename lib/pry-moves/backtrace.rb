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

  include PryMoves::Helpers

  def initialize(pry)
     @pry = pry
  end

  def run_command(param, param2)
    if param.is_a?(String) and (match = param.match /^>(.*)/)
      suffix = match[1].size > 0 ? match[1] : param2
      write_to_file build, suffix
    elsif param and param.match /\d+/
      index = param.to_i
      frame_manager.change_frame_to index
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
    result = []
    show_vapid = %w(+ a all hidden vapid).include?(@filter)
    stack = stack_bindings(show_vapid)
    stack.reject! do |binding|
      binding.eval('__FILE__').match self.class::filter
    end unless %w(a all).include?(@filter)
    build_result stack.reverse, result
  end

  def build_result(stack, result)
    current_object = nil
    stack.each_with_index do |binding|
      obj, debug_snapshot = binding.eval '[self, (debug_snapshot rescue nil)]'
      # Comparison of objects directly may raise exception
      if current_object.object_id != obj.object_id
        result << "#{debug_snapshot || format_obj(obj)}:"
        current_object = obj
      end

      result << build_line(binding)
    end
    result
  end

  def build_line(binding)
    file = shorten_path "#{binding.eval('__FILE__')}"

    signature = method_signature binding
    signature = ":#{binding.frame_type}" if !signature or signature.length < 1

    indent = if frame_manager.current_frame == binding
      '==> '
    elsif @lines_numbers
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

  def stack_bindings(vapid_frames)
    frame_manager.bindings.filter_bindings vapid_frames: vapid_frames
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