Object.class_eval do

  def method_missing(method, *args)
    pry_moves_stack_end = true
    pry_cancel_debug = true

    debug_missing_method = (
      not ([:begin, :to_s, :to_str, :to_int, :to_r, :to_ary, :to_io, :to_hash].include? method)
      #   not caller[0].match PryMoves::Backtrace::filter
    )

    PryMoves.runtime_debug(self) do
      message = self.nil? ?
        "\e[31mCalling \e[1m#{method}\e[0m\e[31m on nil\e[0m" :
        "\e[31mMethod \e[1m#{method}\e[0m\e[31m missing\e[0m"
      [message, self]
    end if debug_missing_method

    super
  end

  def self.const_missing(name)
    super
  rescue => e
    unless PryMoves.open?
      hide_from_stack = true
      message = "😱  \e[31m#{e.to_s}\e[0m"
      PryMoves.debug_error message
    end
    raise
  end unless defined?(Rails)

end if ENV['PRY_MOVES_DEBUG_MISSING'] != 'off' and ENV['PRY_MOVES'] != 'off' and
  not (defined?(Rails) and Rails.env.production?)