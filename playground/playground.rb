# Rails has such type of definitions
Fixnum.send(:alias_method, :to_default_s, :to_s)
Fixnum.send(:define_method, :to_s) do |*args|
  to_default_s(*args)
end

class Playground

  def basic_next
    :basic_1
    binding.pry # basic next stop
    :basic_2 # next step
  end

  def step_into
    binding.pry # step_into stop
    something_inside # point to step inside
  end

  def recursion(depth = 0)
    str = 3.to_s # here fired "return" event when "to_s" patched
    binding.pry if depth == 0
    recursion depth + 1 if depth < 2
    :ok # should stop here after 2 next-s
    # todo: and depth should be 0
  end

  private

  def something_inside
    :something # some internal line
  end

end

