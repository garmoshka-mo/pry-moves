class << Pry
  alias pry_moves_origin_start start

  def start(target = TOPLEVEL_BINDING, options = {})
    if target.is_a?(Binding) && PryMoves.check_file_context(target)
      # Wrap the tracer around the usual Pry.start
      original_verbosity = $VERBOSE
      $VERBOSE = nil # Disable warnings for pry-moves
      PryMoves::PryWrapper.new(target, options, self).run
      $VERBOSE = original_verbosity
    else
      # No need for the tracer unless we have a file context to step through
      pry_moves_origin_start(target, options)
    end
  end

end

Binding.class_eval do

  attr_accessor :index, :hidden

  alias pry_forced pry

  def pry options = nil
    if !Pry.config.disable_breakpoints and
        # Don't start binding.pry when semaphore locked by current thread
        PryMoves.synchronize_threads
      pry_forced options
    end
  end

end

Pry.config.pager = false

Pry::Command.class_eval do
  class << self
    attr_accessor :original_user_input
  end

  alias run_origin_for_pry_moves run
  def run(command_string, *args)
    Pry.config.original_user_input = self.class.original_user_input
    run_origin_for_pry_moves command_string, *args
  ensure
    Pry.config.original_user_input = nil
  end
end

Pry::CommandSet.class_eval do

  alias alias_command_origin_for_pry_moves alias_command

  def alias_command(match, action, options = {})
    cmd = alias_command_origin_for_pry_moves match, action, options
    cmd.original_user_input = match
    cmd
  end

end

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
    lines = ['']

    unless PryMoves.hide_code
      formatter = PryMoves::Formatter.new
      prefix = Thread.current[:pry_moves_debug] ? "👾 " : ""
      # lines << "🍱 #{PryMoves.test_example}" if PryMoves.test_example
      lines << "🦆 step_in_everywhere" if PryMoves.step_in_everywhere
      lines << "#{prefix}#{formatter.shorten_path location}:#{@line} #{me}"
      lines << "   ." + formatter.method_signature(target)
      lines << ''
      lines << "#{code.with_line_numbers(use_line_numbers?).with_marker(marker).highlighted}"
    end
    PryMoves.hide_code = false

    lines << PryMoves::Watch.instance.output(target) unless PryMoves::Watch.instance.empty?
    lines.concat(PryMoves.messages.map do |message|
      message
      # message.length > MAX_MESSAGE_CHARS ?
      #   message[0 .. MAX_MESSAGE_CHARS] + "... (cut)" : message
    end)
    PryMoves.messages.clear

    lines << ''
    lines.join "\n"
  end

  def me
    me = target.eval 'self' rescue nil
    me = PryMoves::Painter.colorize me if me
    me
  end

  def location
    @file
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

Pry::Output.class_eval do

  alias pry_moves_origin_for_puts puts

  def puts *args
    # <first> formatted by Pry.config.print = proc do |output, value|
    first = args[0]
    # Kernel.puts  "Pry::Output.puts: #{first}"
    if first.is_a? String and first.start_with? "(pry) output error"
      first.slice! 400..-1
    end
    pry_moves_origin_for_puts *args
  end

end if defined? Pry::Output
