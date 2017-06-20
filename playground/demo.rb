require 'pry'
require 'pry-moves'

class A

  def initialize
    b = :some_code
  end

  def aa
    self
  end

  def bb
    c = :some_code
    d = :other_code
    self
  end

  def block
    e = :some_code
    yield
    f = :other_code
  end

end

binding.pry
a = A.new.aa.bb
a.block do
  b = :some_code
end
c = :some_code
