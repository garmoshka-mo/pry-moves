def debug
  hide_from_stack = true
  PryMoves.debug
end

def error(msg)
  hide_from_stack = true
  err = "😱  #{msg}"
  if PryMoves.stop_on_breakpoints
    PryMoves.debug err.red
  else
    unless PryMoves.open?
      STDERR.puts err.ljust(80, ' ').red
    end
  end
  raise msg
end

def shit!(err = 'Oh, shit!')
  hide_from_stack = true
  message = "💩  #{err.is_a?(String) ? err : err.message}"
  raise err unless PryMoves.stop_on_breakpoints
  PryMoves.debug message.red
  nil
end

RSpec.configure do |config|

  config.before(:each) do
    PryMoves.launched_specs_examples += 1
    PryMoves.stop_on_breakpoints =
      PryMoves.launched_specs_examples < 2
  end

  config.around(:each) do |example|
    PryMoves.restartable do
      example.run
    end
  end

end if defined? RSpec

Rake::Task.class_eval do

  alias execute_origin_for_pry_moves execute

  def execute(args=nil)
    args ||= EMPTY_TASK_ARGS
    PryMoves.restartable do
      reload_actions
      execute_origin_for_pry_moves args
    end
  end

  def reload_actions
    rake_task_path = actions[0].source_location[0]
    actions.clear
    load rake_task_path
  end

end if defined? Rake
