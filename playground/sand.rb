require 'pry-moves'
require './tracer.rb'


def fi(param)
  a = 2 + 1
  puts param
end

class A

  def initialize
    puts :xuilo
  end

  def aa
    puts 'aa: step 1'
    puts 'aa: step 2'
  end

  def bb
    debug_redirect = :aa
    hide_from_stack = true
    puts 'bb: step 1'
    puts 'bb: step 2'
    aa
  end

  def cc
    koko = :love
    binding.pry
    bb
    (2..4).each do |i|
      puts i
    end
    puts :two
  end
  alias cc_al cc

end

puts :prepare

A.new.cc_al
A.new.cc_al


bb = 1

exit

pp = 123 if debucher?
binding.pry if debucher?

binding.pry

puts :ok
