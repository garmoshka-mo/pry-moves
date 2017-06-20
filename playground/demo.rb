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
      c = :some_code
    end
    d = :some_code
    e = :some_code
    self
  end

  def block
    e = :some_code
    yield
    f = :other_code
  end

end

binding.pry
A.new.aa.bb
c = :some_code
