class PryMoves::ErrorWithData < StandardError

  attr_reader :data
  alias metadata data

  def initialize(msg, data)
    super msg
    @data = data
  end
  
end
