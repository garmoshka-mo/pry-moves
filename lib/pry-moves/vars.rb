module PryMoves::Vars

  extend self

  def var_precedence action, target
    if Pry.config.ignore_once_var_precedence
      Pry.config.ignore_once_var_precedence = false
      return
    end

    input = Pry.config.original_user_input || action.to_s
    return if %w[next debug].include? input # next - ruby keyword
    begin
      binding_value = target.eval(input)
      puts "ℹ️️  Variable \"#{input}\" found. To execute command type its alias or \\#{input}"
      puts PryMoves::Painter.colorize binding_value
      true
    rescue => e
      #   puts (e.backtrace.reverse + ["var_precedence exception:".red, "#{e}".red]).join "\n"
    end
  end

end
