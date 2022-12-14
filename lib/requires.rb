require 'pry' unless defined? Pry
require 'colorize'
require 'diffy'

require 'pry-moves/version'
require 'pry-moves/pry_ext'
require 'pry-moves/commands'
require 'pry-moves/add_suffix'
require 'pry-moves/pry_wrapper'
require 'pry-moves/bindings_stack'
require 'pry-moves/code_reloader'
require 'pry-moves/formatter'
require 'pry-moves/backtrace'
require 'pry-moves/backtrace_builder'
require 'pry-moves/tools'
require 'pry-moves/watch'
require 'pry-moves/diff'
require 'pry-moves/painter'
require 'pry-moves/restartable'
require 'pry-moves/recursion_tracker'
require 'pry-moves/error_with_data'

require 'commands/traced_method'
require 'commands/trace_helpers'
require 'commands/trace_command'
require 'commands/debug'
require 'commands/finish'
require 'commands/goto'
require 'commands/iterate'
require 'commands/next'
require 'commands/next_breakpoint'
require 'commands/step'

require 'pry-stack_explorer/pry-stack_explorer'
require 'sugar/debug_sugar'
require 'sugar/debug_of_missing'

# Optionally load pry-remote monkey patches
require 'pry-moves/pry_remote_ext' if defined? PryRemote