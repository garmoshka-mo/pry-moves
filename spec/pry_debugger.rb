module PryDebugger

  module Breakpoints
    def breakpoints(breakpoints)
      breakpoints.each_with_index do |b, index|
        next_b = breakpoints[index+1]
        b[0] = next_b ? next_b[0] : nil
      end

      PryDebugger.breakpoints =
          breakpoints.map do |b|
            if b[1].is_a? String
              Proc.new do |label|
                expect(label).to eq b[1]
                b[0]
              end
            else
              b
            end
          end
    end
  end

  class InputPipe

    def readline(*args)
      repl_binding = binding.callers[1]
      pry_ = repl_binding.eval('@pry')
      binding_ = pry_.current_binding

      next_cmd = PryDebugger.enter_breakpoint binding_
      next_cmd || 'c'
    end

  end

  class OutputPipe < StringIO

    def print(*args)
      #STDOUT.print *args
      super
    end

    def take_away
      result = string.clone
      truncate(0)
      rewind
      result
    end

  end

  extend self

  def inject
    Pry.config.input = InputPipe.new
    @output = OutputPipe.new
    Pry.config.output = @output
  end

  def breakpoints=(breakpoints)
    @breakpoints_procs = breakpoints
  end

  def enter_breakpoint(binding_)
    raise 'Next breakpoint handler missing' if @breakpoints_procs.size == 0
    output = @output.take_away
    output.match(/^ => .*#(.*)/)
    label = ($1 || '').strip.gsub(/\e\[(\d+)m/, '')
    @breakpoints_procs.shift.call label, binding_, output
  end

end