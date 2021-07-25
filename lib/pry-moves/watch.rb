require 'singleton'
require 'set'

class PryMoves::Watch

  include Singleton

  attr_reader :list

  def initialize
    @list = Set.new
  end

  def process_cmd(cmd, binding_)
    case cmd
      when nil, ''
        if @list.count > 0
          print binding_
        else
          puts "Watch list is empty"
        end
      when '-clear', '-c'
        @list.clear
      else
        add cmd, binding_
    end
  end

  def add(cmd, binding_)
    @list << cmd
    puts eval_cmd(cmd, binding_)
  end

  def print(binding_)
    puts output(binding_) if @list.count > 0
  end

  def output(binding_)
    @list.map do |cmd|
      eval_cmd(cmd, binding_)
    end.join "; "
  end

  def eval_cmd(cmd, binding_)
    "\033[1m#{cmd}\033[0m: #{format binding_.eval(cmd)}"
  rescue NameError
    "\033[1m#{cmd}\033[0m: <undefined>"
  rescue => e
    "\033[1m#{cmd}\033[0m: <#{e}>"
  end

  def format(text)
    Pry::ColorPrinter.pp(text, "").strip
  end

  def empty?
    @list.empty?
  end

end