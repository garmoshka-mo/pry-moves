class PryMoves::Diff

  @@saved_dump = nil

  def initialize(pry, binding)
    @pry = pry
    @binding = binding
  end

  def run_command cmd
    if !@@saved_dump
      @@saved_dump = eval_cmd cmd
      @pry.output.puts "💾 Saved for diff compare:\n".cyan + @@saved_dump
    else
      diff = Diffy::Diff.new(
        @@saved_dump + "\n", eval_cmd(cmd) + "\n"
      ).to_s "color"
      diff = 'Backtraces are equal' if diff.strip.empty?
      @pry.output.puts diff
      @@saved_dump = nil
    end
  end

  private

  def eval_cmd cmd
    "#{@binding.eval(cmd)}"
  end
  
end