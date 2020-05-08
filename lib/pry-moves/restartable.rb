module PryMoves::Restartable

  attr_accessor :restart_requested, :reload_requested

  def restartable
    trigger :new_run
    yield
    re_execution
  rescue PryMoves::Restart
    self.restart_requested = false
    PryMoves.launched_specs_examples = 0
    PryMoves.stop_on_breakpoints = true
    trigger :restart
    retry
  rescue PryMoves::Reload
    puts "🔮  try to use @ with reload"
    exit 3
  end

  def re_execution
    raise PryMoves::Restart if restart_requested
    raise PryMoves::Reload if reload_requested
  end


end

class PryMoves::Restart < RuntimeError
end
class PryMoves::Reload < RuntimeError
end
RSpec::Support::AllExceptionsExceptOnesWeMustNotRescue::AVOID_RESCUING.concat [PryMoves::Restart, PryMoves::Reload] if defined? RSpec

Pry.config.hooks.add_hook(:after_eval, :exit_on_re_execution) do |_, _, _pry_|
  if PryMoves.restart_requested or PryMoves.reload_requested
    Pry.run_command 'exit-all'
  end
end
