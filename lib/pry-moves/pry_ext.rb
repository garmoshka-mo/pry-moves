require 'pry' unless defined? Pry
require 'pry-moves/tracer'

class << Pry
  alias_method :start_without_pry_nav, :start

  def start_with_pry_nav(target = TOPLEVEL_BINDING, options = {})
    old_options = options.reject { |k, _| k == :pry_remote }

    if target.is_a?(Binding) && PryMoves.check_file_context(target)
      # Wrap the tracer around the usual Pry.start
      PryMoves::PryWrapper.new(target, options).run do
        start_without_pry_nav(target, old_options)
      end
    else
      # No need for the tracer unless we have a file context to step through
      start_without_pry_nav(target, old_options)
    end
  end

  alias_method :start, :start_with_pry_nav
end

Binding.class_eval do

  alias pry_forced pry

  def pry
    unless Pry.config.disable_breakpoints
      PryMoves.synchronize_threads
      pry_forced
    end
  end

end

Pry.config.pager = false

Pry::Command::Whereami.class_eval do
  # Negligent function from Pry - evidently poor output format
  # would be wanted to be changed often by developers,
  # but definition so long... :(
  def process
    if bad_option_combination?
      raise CommandError, "Only one of -m, -c, -f, and  LINES may be specified."
    end

    if nothing_to_do?
      return
    elsif internal_binding?(target)
      handle_internal_binding
      return
    end

    set_file_and_dir_locals(@file)

    _pry_.pager.page build_output
  end

  def build_output
    lines = []
    lines << "#{text.bold('From:')} #{location}"
    lines << PryMoves::Watch.instance.output(target) unless PryMoves::Watch.instance.empty?
    lines << ''
    lines << "#{code.with_line_numbers(use_line_numbers?).with_marker(marker).highlighted}"
    lines << ''
    lines.join "\n"
  end

  def location
    me = target.eval 'self' rescue nil
    me = PryMoves::Painter.colorize me if me
    file = defined?(Rails) ? @file.gsub(Rails.root.to_s, '') : @file
    "#{file}:#{@line} #{me}"
  end
end

Pry.config.marker = "=>"
Pry::Code::LOC.class_eval do

  def add_marker(marker_lineno)
    marker = lineno == marker_lineno ?
       Pry.config.marker : "  "
    tuple[0] = " #{marker} #{ line }"
  end

end