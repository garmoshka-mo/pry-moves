require 'pry'
require_relative 'pry_debugger'
require_relative '../playground/playground.rb'

PryDebugger.inject unless ENV['DEBUG']

RSpec.configure do |config|
  config.before(:example) do
    PryMoves.unlock if PryMoves.semaphore.locked?
  end
  config.after(:example) do |example|
    unless example.exception
      expect(PryDebugger.breakpoints.count).to be(0), "not all breakpoints launched"
    end
  end
end

RSpec::Core::BacktraceFormatter.class_eval do

  alias :native_backtrace_line :backtrace_line

  def format_backtrace(backtrace, options={})
    return [] unless backtrace
    return backtrace if options[:full_backtrace] || backtrace.empty?

    @lines = 0
    backtrace.map { |l| backtrace_line(l) }.compact
  end

  FILTER = /(\/gems\/|\/lib\/pry\/|spec\/pry_debugger\.rb)/
  def backtrace_line(line)
    return if @lines == 3 and not ENV['TRACE']
    #return if line.match FILTER
    return unless line.include? '/playground.rb'

    result = native_backtrace_line(line)
    if result
      @lines += 1 if @lines
      result[0 .. 1] == './' ? result[2 .. -1] : result
    end
  end

end

Pry::REPL.class_eval do
  def handle_read_errors
    yield
  end
end