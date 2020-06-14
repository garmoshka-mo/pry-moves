require 'pry' unless defined? Pry

module PryMoves
  Commands = Pry::CommandSet.new do
    block_command 'step', 'Step execution into the next line or method.' do |param|
      breakout_navigation :step, param
    end
    alias_command 's', 'step'

    block_command 'finish', 'Finish - xule tut neponyatnogo' do |param|
      breakout_navigation :finish, param
    end
    alias_command 'f', 'finish'

    block_command 'next', 'Execute the next line stepping into blocks' do |param|
      breakout_navigation :next, param
    end
    alias_command 'n', 'next'

    block_command 'nn', 'Execute the next line skipping blocks' do |param|
      breakout_navigation :next, 'blockless'
    end

    block_command 'next_breakpoint', 'Go to next breakpoint' do |param|
      breakout_navigation :next_breakpoint, param
    end
    alias_command 'b', 'next_breakpoint'

    block_command 'iterate', 'Go to next iteration of current block' do |param|
      breakout_navigation :iterate, param
    end

    block_command 'goto', 'goto line' do |param|
      breakout_navigation :goto, param
    end
    alias_command 'g', 'goto'

    block_command 'continue', 'Continue program execution and end the Pry session' do
      PryMoves.show_vapid_frames = false
      check_file_context
      run 'exit-all'
    end
    alias_command 'c', 'continue'

    block_command 'watch', 'Display value of expression on every move' do |param|
      PryMoves::Watch.instance.process_cmd param, target
    end

    block_command 'bt', 'Backtrace' do |param, param2|
      PryMoves::Backtrace.new(_pry_).run_command param, param2
    end

    block_command 'debug', '' do
      cmd = arg_string.gsub(/^debug/, '').strip
      breakout_navigation :debug, cmd
    end

    block_command :restart, '' do
      PryMoves.restart_requested = true
      run 'continue'
    end
    alias_command '@', 'restart'

    block_command :reload, '' do
      PryMoves.reload_requested = true
      run 'continue'
    end
    alias_command '#', 'reload'

    block_command '!', 'exit' do
      PryMoves.unlock
      Pry.config.exit_requested = true
      run '!!!'
    end

    # Hit Enter to repeat last command
    command /^$/, "repeat last command" do
      _pry_.run_command Pry.history.to_a.last
    end

    helpers do
      def breakout_navigation(action, param)
        input = Pry.config.original_user_input
        binding_value = target.eval(input) rescue nil
        unless binding_value.nil?
          puts PryMoves::Painter.colorize binding_value
          return
        end

        check_file_context
        _pry_.binding_stack.clear     # Clear the binding stack.
        throw :breakout_nav, {        # Break out of the REPL loop and
          action: action,          #   signal the tracer.
          param:  param,
          binding: target
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
