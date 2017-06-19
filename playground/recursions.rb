require 'pry'
require 'pry-moves'

class Test

  def initialize(i)
    @index = i
  end

  def test
    a = 1
    b = 2
  end

  def pimpa
    pop = 3
    pop = 4
  end

  def small
    binding.pry
    p = 1
  end

  def zaloop(p = -1)
    op = p
    binding.pry if p == 0 and @index == 2
    #raise 'abc'
    iterator do |i|
      aa = 1
      zaloop i if op == -1
      aa = 2
      aa = 2
    end
  rescue
    a = 3
  end

  def straight
    popa = 1
    a = binding
    iterator do |i|
      b = binding
      pop = 1
      pop = i
      pop = 2
      #binding.pry
    end
  end

  def iterator
    1.times do |i|
      pop = 1
      yield i
      pop = 2
    end
  end

end

threads = 10.times.map do |i|
  Thread.new do
    t = Test.new i
    #t.small
    t.zaloop rescue a = :caught
    #t.straight
  end
end
threads.each(&:join)


puts :zoo
puts :zoo2

exit

t.test and t.pimpa

puts "here_goes_end\n"
