# cd playground
# be ruby sand.rb

require 'pry-moves'
require './tracer.rb'


def fi(param)
  a = 2 + 1
  puts param
end

class Sand

  def initialize
    puts :xuilo
  end

  def some_logic
    puts 'aa: step 1'
    puts 'aa: step 2'
  end

  def method_with_hidden_stack
    debug_redirect = :aa
    hide_from_stack = true
    puts 'bb: step 1'
    puts 'bb: step 2'
    some_logic
  end

  def debugged_method
    koko = :love
    debug
    method_with_hidden_stack
    (2..4).each do |i|
      puts i
    end
    puts :two
  end
  alias debugged_method_alias debugged_method

end

puts :prepare

Sand.new.method_with_hidden_stack


bb = 1

exit

pp = 123 if debucher?
binding.pry if debucher?

binding.pry

puts :ok
