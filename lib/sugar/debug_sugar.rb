def debug *args
  return binding.pry_forced if args.first == :forced
  pry_moves_stack_end = true
  PryMoves.debug *args
end

def error(msg = "Error", debug_object = nil)
  pry_moves_stack_end = true
  err = "😱  #{msg}"
  unless PryMoves.open?
    if PryMoves.stop_on_breakpoints
      lines = [err.red]
      lines.prepend debug_object.ai if debug_object
      PryMoves.error lines.join("\n")
    else
      STDERR.puts debug_object.ai if debug_object
      STDERR.puts err.ljust(80, ' ').red
    end
  end
  raise PryMoves::ErrorWithData.new(msg, debug_object)
end

def shit!(err = 'Oh, shit!', debug_object = nil)
  return if ENV['NO_SHIT']
  pry_moves_stack_end = true
  message = "💩  #{err.is_a?(String) ? err : err.message}"
  raise err unless PryMoves.stop_on_breakpoints
  lines = [message.red]
  lines.prepend debug_object.ai if debug_object
  PryMoves.error lines.join("\n")
  nil
end

def required(var)
  pry_moves_stack_end = true
  error("required parameter is missing") if var.nil?
  var
end

RSpec.configure do |config|

  config.before(:each) do
    PryMoves.launched_specs_examples += 1
    PryMoves.stop_on_breakpoints =
      RSpec.configuration.world.example_count == 1
  end

  config.around(:each) do |example|
    PryMoves.restartable(rspec_example: example) do
      example.run
    end
  end

end if defined? RSpec

Rake::Task.class_eval do

  alias execute_origin_for_pry_moves execute

  def execute(args=nil)
    args ||= EMPTY_TASK_ARGS
    PryMoves.restartable(rake_args: args) do |context|
      reload_actions if PryMoves.reload_rake_tasks and context[:retry] > 0
      execute_origin_for_pry_moves args
    end
  end

  def reload_actions
    rake_task_path = actions[0].source_location[0]
    actions.clear
    load rake_task_path
  end

end if defined? Rake and defined? Rake::Task

Diffy.module_eval do

  class << self
    def diff text1, text2
      diff = Diffy::Diff.new(
        text1 + "\n", text2 + "\n"
      ).to_s "color"
      diff = 'Outputs are equal' if diff.strip.empty?
      diff
    end
  end

end