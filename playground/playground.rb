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
  
  def skip_hidden_impl
    binding.pry # skip_hidden_impl stop
    hidden_self.something_inside # point to step inside
  end

  def hidden_self
    hide_from_stack = true # hidden_self 1
    self # hidden_self 2
  end

  def hidden_stop
    hide_from_stack = true
    binding.pry # hidden stop
    dummy = :ok_next # hidden_stop for next
    dummy = :ok_step # hidden_stop for step
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

  def step_by_name
    binding.pry # stop in step_by_name
    level_a.level_c(:target)
  end

  def step_by_name_wrap
    step_by_name
    :after_step_by_name # after_step_by_name
  end
  
  def early_return_wrap
    early_return
    :after_return # after early return
  end
  
  def early_return
    return true if level_c # at early return
    dummy = 1
  end

  def level_a
    level_b # inside of level_a
  end

  def level_b
    hide_from_stack = true
    level_c
  end

  def level_c(param = nil)
    binding.pry # stop in level_c
    self
  end # exit from level_c

  def nested_block(early_return: false)
    binding.pry # stop in nested_block
    iterator do |i| # iterator line
      dummy = 1 # inside block
      return if early_return
    end
    :after_block # after block
  end
  
  def native_block(early_return: false)
    binding.pry # stop in native_block
    2.times do |i| # iterator line
      dummy = 1 # inside block
      return if early_return
    end
    :after_block # after block
  end

  def one_line_in_block
    binding.pry # stop in one_line_in_block
    iterator do |i| # iterator line
      dummy = 1 # inside block
    end
    :after_block # after block
  end

  def one_line_block
    binding.pry # stop in one_line_block
    iterator { |i| dummy = 1 } # iterator line
    :after_block # after block
  end
  
  def parentheses_in_loop
    binding.pry # stop in parentheses_in_loop
    i = 2
    while (i = i - 1) > 0 # iterator line
      dummy = 1 # inside block
    end
    :after_block # after block
  end

  def zaloop(pass = :root)
    binding.pry if pass == :root # stop in zaloop
    iterator do |i| # iterator line
      dummy = 1 # inside block
      zaloop i if pass == :root
      return unless pass == :root # after sub-zaloop
    end
    :after_block # after block
  end # exit from zaloop

  def method_with_redirection
    debug_redirect = :level_a # at method_with_redirection
    level_a
  end

  def instant_redirection
    debug_redirect = '=something_inside'
    binding.pry # at instant_redirection
    something_inside
  end

  def redirection_host
    binding.pry # redirection host
    method_with_redirection
  end

  def something_inside
    :something # some internal line
  end
  
  def method_with_breakpoints
    binding.pry # method_with_breakpoints host
    dummy = 1 # some internal line
    method_with_breakpoint # breakpoint
    dummy = 1 # after breakpoint
    dummy = 1 # after after breakpoint
    method_with_breakpoint # breakpoint 2
    dummy = 1 # after breakpoint 2
  end

  def method_with_breakpoint
    pry_breakpoint = true
    hide_from_stack = true
  end

  def skip_test
    binding.pry # stop in skip_test
    skipped_method.not_skipped_method # next step
  end

  def skipped_method
    pry_moves_skip = true # at skipped_method
    self # at skipped_method
  end

  def not_skipped_method
    :not_skipped_method # at not_skipped_method
  end

  private

  def iterator
    2.times do |i|
      dummy = :pre_yield # pre_yield
      yield i
      :post_yield # post_yield
    end
  end # exit from iterator
  
  def debug_
    :something # inside of debug method
  end

end

