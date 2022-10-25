class PryMoves::Tools

  def initialize pry
    @pry = pry
  end

  def add_breakpoint var_name, line_number, binding
    file, line = binding.eval('[__FILE__, __LINE__]')
    line_number ||= line
    lines = IO.readlines(file)

    value = binding.eval(var_name)
    value = value.to_json if value.is_a? String
    lines.insert line_number-1, "debug if #{var_name} == #{value}"

    File.open(file, 'w') do |file|
      file.puts lines
    end
    @pry.output.puts "🔴 Breakpoint added to #{File.basename file}:#{line_number}"
  end

end