module PryDebugger

  class InputPipe

    def initialize(first_cmd)
      @first_cmd = first_cmd
    end

    def readline(*args)
      if @first_cmd
        next_cmd = @first_cmd
        @first_cmd = nil
      else
        repl_binding = binding.callers[1]
        pry_ = repl_binding.eval('@pry')
        binding_ = pry_.current_binding

        next_cmd = PryDebugger.enter_breakpoint binding_
      end

      next_cmd
    end

  end

  extend self

  def reset
    @breakpoints_procs = []
  end

  def on_next_breakpoint(&block)
    @breakpoints_procs << block
  end

  def enter_breakpoint(target)
    @breakpoints_procs.shift.call target
  end

  def intercept(target, options)
    raise 'Next breakpoint handler missing' if @breakpoints_procs.size == 0

    #output = StringIO.new
    #options[:output] = output

    next_cmd = enter_breakpoint target

    input = InputPipe.new next_cmd
    options[:input] = input
  end

end