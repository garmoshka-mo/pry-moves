require 'pry-moves'

Thread.current[:name] = 'main'

a = Thread.new do
  Thread.current[:name] = 'a'
  sleep 0.2
  puts 'a'
  binding.pry
  puts 'aaaa'
  sleep 1
  puts 'aaa'
end

b = Thread.new do
  Thread.current[:name] = 'b'
  20223000.times do
    432 * 3232
  end
  puts '2'
  binding.pry
  puts '22'
end

a.join
b.join