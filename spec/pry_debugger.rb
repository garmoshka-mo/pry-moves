module PryDebugger

  module Breakpoints
    def breakpoints(breakpoints)
      steps = []
      breakpoints.each_with_index do |b, index|
        next_b = breakpoints[index+1]
        steps << {
          cmd: b[0],
          expected: b[1],
          next_cmd: next_b ? next_b[0] : nil,
          index: index
        }
      end

      PryDebugger.breakpoints =
          steps.map do |step|
            Proc.new do |label, binding_, output|
              compare(step, label, binding_, output)
              step[:next_cmd]
            end
          end
    end

    def compare(step, label, binding_, output)
      exp = step[:expected]
      puts "\nSTEP #{step[:index]}:\n#{output}" if ENV['PRINT']
      if exp.is_a? Proc
        exp.call binding_, output
      elsif exp.is_a? Hash
        if exp[:output_includes]
          expect(output).to include exp[:output_includes]
        else
          err = <<-TEXT
[#{step[:index]}] #{step[:cmd]} expected output '#{exp[:output]}', got '#{output}'
          TEXT
          expect(output).to eq(exp[:output]), err
        end
      elsif not exp.nil?
        err = <<-TEXT
[#{step[:index]}] #{step[:cmd]} => '#{exp}', got '#{label}'
        TEXT
        expect(label).to eq(exp), err
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
    #puts (@breakpoint_call += 1)
    output = @output.take_away
    output.match(/^ (=>|⛔️) .*#(.*)/)
    label = ($2 || '').strip
    @breakpoints_procs.shift.call label, binding_, output.strip
  end

end