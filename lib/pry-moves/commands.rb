require 'pry' unless defined? Pry

module PryMoves
  Commands = Pry::CommandSet.new do
    block_command 'step', 'Step execution into the next line or method.' do |param|
      check_file_context
      breakout_navigation :step, param
    end

    block_command 'finish', 'Finish xule tut neponyatnogo.' do |param|
      check_file_context
      breakout_navigation :finish, param
    end

    block_command 'next', 'Execute the next line within the same stack frame.' do |param|
      check_file_context
      breakout_navigation :next, param
    end

    block_command 'continue', 'Continue program execution and end the Pry session.' do
      check_file_context
      run 'exit-all'
    end

    block_command 'watch', 'Display value of expression on every move' do |param|
      PryMoves::Watch.instance.process_cmd param, target
    end

    block_command 'bt', 'Backtrace' do |param|
      PryMoves::Backtrace.new(target).run_command param
    end

    alias_command 'c', 'continue'
    alias_command 's', 'step'
    alias_command 'n', 'next'
    alias_command 'f', 'finish'

    # Hit Enter to repeat last command
    command /^$/, "repeat last command" do
      _pry_.run_command Pry.history.to_a.last
    end

    helpers do
      def breakout_navigation(action, param)
        _pry_.binding_stack.clear     # Clear the binding stack.
        throw :breakout_nav, {        # Break out of the REPL loop and
          :action => action,          #   signal the tracer.
          :param =>  param,
          :binding => target
        }
      end

      # Ensures that a command is executed in a local file context.
      def check_file_context
        unless PryMoves.check_file_context(target)
          raise Pry::CommandError, 'Cannot find local context. Did you use `binding.pry`?'
        end
      end
    end
  end
end

Pry.commands.import PryMoves::Commands

Pry.commands.alias_command '!', '!!!'
