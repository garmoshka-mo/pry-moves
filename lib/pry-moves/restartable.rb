module PryMoves::Restartable

  attr_accessor :restart_requested, :reload_requested,
    :reload_ruby_scripts, :reloader,
    :reload_rake_tasks

  def restartable context
    trigger :each_new_run, context
    context[:retry] ||= 0
    PryMoves.reloader&.reload if context[:retry] > 0
    yield context
    re_execution # todo: maybe mark restart_request for thread? not globally?
  rescue PryMoves::Restart
    puts "🔄️  Restarting execution"
    PryMoves.reset
    trigger :restart, context
    context[:retry] += 1
    retry
  rescue PryMoves::Reload
    puts "🔮  try to use @ with reload"
    exit 3
  end

  def re_execution
    if restart_requested
      self.restart_requested = false
      raise PryMoves::Restart
    end
    raise PryMoves::Reload if reload_requested
  end

  def reload_sources
    PryMoves.reloader&.reload
  end
  
end

class PryMoves::Restart < Exception
end
class PryMoves::Reload < Exception
end
RSpec::Support::AllExceptionsExceptOnesWeMustNotRescue::AVOID_RESCUING.concat [PryMoves::Restart, PryMoves::Reload] if defined? RSpec

Pry.config.hooks.add_hook(:after_eval, :exit_on_re_execution) do |_, _, _pry_|
  if PryMoves.restart_requested or PryMoves.reload_requested
    Pry.run_command 'exit-all'
  end
end
