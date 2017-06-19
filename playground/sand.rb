require 'pry'
require 'pry-moves'
require './tracer.rb'

def debug?
  binding.pry
  true
end

#trace_events

a = 1123

puts :prepare

binding.pry

pp = 123 if debug?
binding.pry if debug?

binding.pry

puts :ok
