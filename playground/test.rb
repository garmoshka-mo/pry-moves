require 'pry-moves'
require_relative '../playground/playground.rb'

i = Playground.new
if ARGV[0]
  i.send ARGV[0]
else
  i.zaloop
end
