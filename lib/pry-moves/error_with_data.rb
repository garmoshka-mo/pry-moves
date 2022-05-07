class PryMoves::ErrorWithData < StandardError

  attr_reader :metadata

  def initialize(msg, metadata)
    super msg
    @metadata = metadata
  end

end