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
    puts :ko
    puts :ki
  end

  def bb
    debug_redirect = :aa
    hide_from_stack = true
    a = 1
    b = 1
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
