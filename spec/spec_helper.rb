require 'pry'
require_relative 'pry_debugger'
require_relative '../playground/playground.rb'

PryDebugger.inject

RSpec::Core::BacktraceFormatter.class_eval do

  alias :native_format_backtrace :format_backtrace
  alias :native_backtrace_line :backtrace_line

  def format_backtrace(backtrace, options={})
    @lines = 0
    native_format_backtrace backtrace, options
  end

  def backtrace_line(line)
    return if @lines == 3 and not ENV['TRACE']
    return if line.include? '/gems/' or line.include? '/treat/'

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