module PryDebugger

  module Breakpoints
    def breakpoints(breakpoints)
      breakpoints.each_with_index do |b, index|
        next_b = breakpoints[index+1]
        b[0] = next_b ? next_b[0] : nil
      end

      PryDebugger.breakpoints =
          breakpoints.map do |b|
            Proc.new do |label, binding_, output|
              compare(b[1], label, binding_, output)
              b[0]
            end
          end
    end

    def compare(subj, label, binding_, output)
      if subj.is_a? Proc
        subj.call binding_, output
      elsif subj.is_a? Hash
        if subj[:out_include]
          expect(output).to include subj[:out_include]
        else
          expect(output).to eq subj[:out]
        end
      elsif not subj.nil?
        expect(label).to eq subj
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
      result.gsub(/\e\[([;\d]+)?m/, '')
    end

  end

  extend self

  def inject
    Pry.config.input = InputPipe.new
    @output = OutputPipe.new
    Pry.config.output = @output
  end

  def breakpoints
    @breakpoints_procs
  end

  def breakpoints=(breakpoints)
    @breakpoints_procs = breakpoints
    @breakpoint_call = 0
  end

  def enter_breakpoint(binding_)
    raise 'Next breakpoint handler missing' if @breakpoints_procs.size == 0
    puts (@breakpoint_call += 1)
    output = @output.take_away
    output.match(/^ => .*#(.*)/)
    label = ($1 || '').strip
    @breakpoints_procs.shift.call label, binding_, output.strip
  end

end