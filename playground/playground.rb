# Rails has such type of definitions
Fixnum.send(:alias_method, :to_default_s, :to_s)
Fixnum.send(:define_method, :to_s) do |*args|
  to_default_s(*args)
end

class Playground

  def basic_next
    dummy = :basic_1
    binding.pry # basic next stop
    :basic_2 # next step
  end

  def step_into
    binding.pry # step_into stop
    something_inside # point to step inside
  end

  def continue
    binding.pry # first stop
    dummy = :something
    binding.pry # second stop
  end

  def recursion(depth = 0)
    str = 3.to_s # here fired event "return" if "to_s" patched
    binding.pry if depth == 0
    recursion depth + 1 if depth < 2 # next step
    :ok # should stop here after 2 next-s
  end

  def level_a
    level_b # inside of level_a
  end

  def level_b
    hide_from_stack = true
    level_c
  end

  def level_c
    binding.pry # stop in level_c
    self
  end

  def with_simple_block
    binding.pry # stop in with_simple_block
    iterator do |i|
      dummy = 1 # inside block
      dummy = 2
    end
    :after_block # after block
  end

  def zaloop(pass = :root)
    binding.pry if pass == :root # stop in zaloop
    iterator do |i|
      dummy = 1 # inside block
      zaloop i if pass == :root
    end
    :after_block # after block
  end

  private

  def iterator
    2.times do |i|
      dummy = :pre_yield # pre_yield
      yield i
      :post_yield # post_yield
    end
  end

  def something_inside
    :something # some internal line
  end

end

