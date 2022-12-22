Object.class_eval do

  def method_missing(method, *args)
    pry_moves_stack_end = true
    pry_cancel_debug = true

    debug_missing_method = (
      not method.in?([:begin, :to_s, :to_str, :to_int, :to_ary, :to_io, :to_hash]) and
        not caller[0].match PryMoves::Backtrace::filter
    )

    PryMoves.runtime_debug(self) do
      message = self.nil? ?
        "\e[31mCalling \e[1m#{method}\e[0m\e[31m on nil\e[0m" :
        "\e[31mMethod \e[1m#{method}\e[0m\e[31m missing\e[0m"
      subject = self.ai rescue "#{self.class} #{self}"
      "#{subject}\n" +
        "😱  #{message}"
    end if debug_missing_method

    super
  end

  def should_be *classes
    hide_from_stack = true
    if self && !classes.some?{self.is_a?(_1)}
      error("Expected class #{classes.join ", "}, got #{self.class.ai}", self)
    end
    self
  end

  def self.const_missing(name)
    super
  rescue => e
    unless PryMoves.open?
      hide_from_stack = true
      message = "😱  \e[31m#{e.to_s}\e[0m"
      PryMoves.error message
    end
    raise
  end unless defined?(Rails)

end if ENV['PRY_MOVES_DEBUG_MISSING'] != 'off' and ENV['PRY_MOVES'] != 'off' and
  not (defined?(Rails) and Rails.env.production?)