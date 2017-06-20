require 'pry-moves/version'
require 'pry-moves/pry_ext'
require 'pry-moves/commands'
require 'pry-moves/tracer'
require 'pry-moves/backtrace'

# Optionally load pry-remote monkey patches
require 'pry-moves/pry_remote_ext' if defined? PryRemote

module PryMoves
  TRACE_IGNORE_FILES = Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].map { |f| File.expand_path(f) }

  extend self

  # Checks that a binding is in a local file context. Extracted from
  # https://github.com/pry/pry/blob/master/lib/pry/default_commands/context.rb
  def check_file_context(target)
    file = target.eval('__FILE__')
    file == Pry.eval_path || (file !~ /(\(.*\))|<.*>/ && file != '' && file != '-e')
  end

  # Reference to currently running pry-remote server. Used by the tracer.
  attr_accessor :current_remote_server
end
