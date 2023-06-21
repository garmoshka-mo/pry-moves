def debug *args
  return binding.pry_forced if [:force, :forced].include? args.first
  pry_moves_stack_end = true
  PryMoves.debug *args
end

def error(err = "Error", debug_object = nil)
  pry_moves_stack_end = true
  message = "😱  #{err}"
  debug_object ||= err.metadata if err.respond_to? :metadata
  unless PryMoves.open?
    if PryMoves.stop_on_breakpoints
      PryMoves.debug_error message.red, debug_object
    else
      STDERR.puts PryMoves.format_debug_object(debug_object) if debug_object
      STDERR.puts message.ljust(80, ' ').red
    end
  end
  err = PryMoves::ErrorWithData.new(err, debug_object) unless err.is_a? Exception
  raise err
end

def shit!(err = 'Oh, shit!', debug_object = nil)
  return if ENV['NO_SHIT']
  pry_moves_stack_end = true
  message = "💩  #{err.is_a?(String) ? err : err.message}"
  raise err unless PryMoves.stop_on_breakpoints
  lines = [message.red]
  lines.prepend debug_object.ai if debug_object
  PryMoves.debug_error lines.join("\n")
  nil
end

Object.class_eval do

  def required!
    pry_moves_stack_end = true
    error("required parameter is missing", self) if self.nil?
    self
  end

  def should_be *classes
    hide_from_stack = true
    if self && !classes.some?{self.is_a?(_1)}
      error("Expected class #{classes.join ", "}, got #{self.class.ai}", self)
    end
    self
  end

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

end if ENV['PRY_MOVES'] != 'off' and defined? RSpec

Rake::Task.class_eval do

  alias execute_origin_for_pry_moves execute

  def execute(args=nil)
    args ||= EMPTY_TASK_ARGS
    PryMoves.restartable(rake_args: args, name: self.name) do |context|
      reload_actions if PryMoves.reload_rake_tasks and context[:retry] > 0
      execute_origin_for_pry_moves args
    end
  end

  def reload_actions
    rake_task_path = actions[0].source_location[0]
    actions.clear
    load rake_task_path
  end

end if ENV['PRY_MOVES'] != 'off' and defined? Rake and defined? Rake::Task

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
