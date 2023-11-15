require 'requires.rb'

module PryMoves
  TRACE_IGNORE_FILES = Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].map { |f| File.expand_path(f) }

  extend self
  extend PryMoves::Restartable

  attr_accessor :is_open, :trace, :stack_tips,
    :stop_on_breakpoints, :dont_print_errors,
    :test_example, :launched_specs_examples,
    :debug_called_times, :step_in_everywhere

  def loop
    Kernel.loop do
      result = yield
      debug "⏸  execution loop complete\n#{result}"
      PryMoves.reload_sources
    end
  end

  def stop_on_breakpoints?
    stop_on_breakpoints
  end

  def switch
    self.stop_on_breakpoints = !self.stop_on_breakpoints
    if self.stop_on_breakpoints
      puts '🪲  Debugging is turned on'
    else
      puts '🐞 Debugging is turned off'
    end
  end

  def listen_signal_to_switch use_signals = %w[INFO QUIT]
    # signals list in bash: stty -a
    signal = use_signals.find {Signal.list[_1]}
    unless signal
      puts "No signals supported for PryMoves switch: #{use_signals}"
      return
    end

    puts "🚥 Overriding #{signal} signal for PryMoves debug switch"
    Signal.trap signal do
      PryMoves.switch
    end
  end

  def debug_window_attached?
    if !@last_attachment_check or Time.now - @last_attachment_check > 2
      @is_debug_window_attached = begin
        @last_attachment_check = Time.now
        if `echo $STY` # is in screen
          my_window = `echo $WINDOW`.strip
          windows_list = `screen -Q windows`
          windows_list.include? " #{my_window}*" # process is in currently active window
        else
          true
        end
      end
    else
      @is_debug_window_attached
    end
  end

  def init
    reset
    self.trace = true if ENV['TRACE_MOVES']
    self.reload_ruby_scripts = {
      monitor: %w(app test spec),
      except: %w(app/assets app/views)
    }
    self.reloader = CodeReloader.new unless ENV['PRY_MOVES_RELOADER'] == 'off'
    self.reload_rake_tasks = true
  end

  def reset
    self.launched_specs_examples = 0
    unless ENV['PRY_MOVES'] == 'off' ||
        (defined?(Rails) and Rails.env.production?)
      self.stop_on_breakpoints = STDIN.tty? && STDOUT.tty?
    end
    self.debug_called_times = 0
    self.step_in_everywhere = false
  end

  def debug(message = nil, data: nil, at: nil, from: nil, options: nil)
    pry_moves_stack_end = true
    message ||= data
    PryMoves.re_execution
    if PryMoves.stop_on_breakpoints?
      self.debug_called_times += 1
      return if at and self.debug_called_times != at
      return if from and self.debug_called_times < from
      if message
        PryMoves.messages << (message.is_a?(String) ? message : message.ai)
      end
      binding.pry options
      PryMoves.re_execution
    end
  end

  ROOT_DIR = File.expand_path(".")

  def runtime_debug(instance, external: false)
    do_debug = (
      stop_on_breakpoints? and
        not open? and
        (external or is_project_file?) and
        not [RubyVM::InstructionSequence].include?(instance)
    )
    if do_debug
      hide_from_stack = true
      err, obj = yield
      # HINT: when pry failed to start use: caller.reverse
      PryMoves.debug_error err, obj
      true
    end
  end

  def is_project_file?
    files = caller[2..4] # -2 steps upside: runtime_debug, debug sugar function
    files.any? do |file|
      !file.start_with?("/") || file.start_with?(ROOT_DIR)
    end
  end

  MAX_MESSAGE_CHARS = 520
  def format_debug_object obj
    output = obj.ai rescue "#{obj.class} #{obj}"
    output.length > MAX_MESSAGE_CHARS ?
      output[0 .. MAX_MESSAGE_CHARS] + "... (cut)" : output
  end

  def debug_error(message, debug_object=nil)
    pry_moves_stack_end = true
    if debug_object
      message = [format_debug_object(debug_object), message].join "\n"
    end
    debug message, options: {is_error: true}
  end

  # Checks that a binding is in a local file context. Extracted from
  # https://github.com/pry/pry/blob/master/lib/pry/default_commands/context.rb
  def check_file_context(target)
    file = target.eval('__FILE__')
    file == Pry.eval_path || (file !~ /(\(.*\))|<.*>/ && file != '' && file != '-e')
  end

  def semaphore
    @semaphore ||= Mutex.new
  end

  def messages
    @messages ||= []
  end

  def add_command(command, &block)
    Pry.commands.block_command command, "", &block
  end

  def locked?
    semaphore.locked?
  end
  alias tracing? locked?

  def lock
    semaphore.lock unless semaphore.locked?
  end

  def unlock
    semaphore.unlock unless Thread.current[:pry_moves_debug]
  end

  def open?
    @is_open
  end

  def synchronize_threads
    return true if Thread.current[:pry_moves_debug]

    semaphore.synchronize {} rescue return
    true
  end

  def trigger(event, context)
    triggers[event].each {|t| t.call context}
  end

  def triggers
    @triggers ||= Hash.new do |hash, key|
      hash[key] = []
    end
  end

  TRIGGERS = [:each_new_run, :restart]
  def on(trigger, &block)
    error "Invalid trigger, possible triggers: #{TRIGGERS}", trigger unless TRIGGERS.include? trigger
    triggers[trigger] << block
  end

  # Reference to currently running pry-remote server. Used by the tracer.
  attr_accessor :current_remote_server
end

PryMoves.init

require 'sugar/debug_of_missing' # After PryMoves loaded
