# Rails has such type of definitions
Fixnum.send(:alias_method, :to_default_s, :to_s)
Fixnum.send(:define_method, :to_s) do |*args|
  to_default_s(*args)
end

class Playground

  def basic_breakpoint
    puts :basic_1
    binding.pry
    puts :basic_2
    puts :basic_3
    puts :basic_4
    #binding.pry
  end

  def recursion(depth = 0)
    str = 3.to_s # here fired "return" event when "to_s" patched
    binding.pry if depth == 0
    recursion depth + 1 if depth < 2
    :ok # should stop here after 2 next-s
    # todo: and depth should be 0
  end

end

