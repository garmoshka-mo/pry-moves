require 'pry-moves'

class A

  def initialize
    b = :some_code
  end

  def aa
    self
  end

  def pre_bb
    [1,2,3].each do
      bb
    end
    puts :prebb
  end

  def bb
    binding.pry
    block_func do
      #cc
      ff
      a = :some_code
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

  def ff
    e = :ff
  end

  def block_func
    e = :some_code
    [1,1].each do
      yield
    end
    f = :other_code
  end

end

#binding.pry
puts :aaa
A.new.aa.pre_bb
c = :some_code
puts :zzz
