require 'pry-moves'

class A

  def initialize
    b = :some_code
  end

  def aa
    self
  end

  def bb
    block do
      cc
      c = :some_code
    end
    d = :some_code
    e = :some_code
    self
  end

  def cc
    dd_vapid
  end

  def dd_vapid
    hide_from_stack = true
    ee
  end

  def ee
    binding.pry
  end

  def block
    e = :some_code
    [1].each do
      yield
    end
    f = :other_code
  end

end

#binding.pry
puts :aaa
A.new.aa.bb
c = :some_code
puts :zzz
