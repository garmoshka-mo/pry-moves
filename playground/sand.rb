require 'pry'
require 'pry-moves'
#require 'pry-nav'
require './tracer.rb'

def debug?
  binding.pry
  true
end

class A

  def initialize
    puts :xuilo
  end

  def aa
    self
  end

  def bb
    #binding.pry
    a = 1
    a = 1
    self
  end

  def cc
    self
  end

end

#trace_events

a = 1123

puts :prepare

binding.pry

A.new.aa.bb.cc

bb = 1

exit

pp = 123 if debug?
binding.pry if debug?

binding.pry

puts :ok
