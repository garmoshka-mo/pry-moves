require 'pry' unless defined? Pry

require 'pry-moves/version'
require 'pry-moves/trace_commands'
require 'pry-moves/traced_method'
require 'pry-moves/tracer'
require 'pry-moves/pry_ext'
require 'pry-moves/commands'
require 'pry-moves/pry_wrapper'
require 'pry-moves/backtrace'
require 'pry-moves/watch'
require 'pry-moves/helpers'
require 'pry-moves/painter'

require 'pry-stack_explorer/pry-stack_explorer'

# Optionally load pry-remote monkey patches
require 'pry-moves/pry_remote_ext' if defined? PryRemote

module PryMoves
  TRACE_IGNORE_FILES = Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].map { |f| File.expand_path(f) }

  extend self

  attr_accessor :is_open

  # Checks that a binding is in a local file context. Extracted from
  # https://github.com/pry/pry/blob/master/lib/pry/default_commands/context.rb
  def check_file_context(target)
    file = target.eval('__FILE__')
    file == Pry.eval_path || (file !~ /(\(.*\))|<.*>/ && file != '' && file != '-e')
  end

  def semaphore
    @semaphore ||= Mutex.new
  end

  def locked?
    semaphore.locked?
  end

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

  # Reference to currently running pry-remote server. Used by the tracer.
  attr_accessor :current_remote_server
end
