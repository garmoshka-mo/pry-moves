class PryMoves::Backtrace

  class << self
    def lines_count; @lines_count || 5; end
    def lines_count=(f); @lines_count = f; end

    def filter
      @filter || /(\/gems\/|\/rubygems\/|\/bin\/|\/lib\/ruby\/|\/pry-moves\/)/
    end
    def filter=(f); @filter = f; end

    def format(&block)
      @formatter = block
    end

    def formatter
      @formatter || lambda do |line|
        if defined? Rails
          line.gsub( /^#{Rails.root.to_s}/, '')
        else
          line
        end
      end
    end
  end

  def initialize(binding)
     @binding = binding
  end

  def build(lines_count = :all)
    lines = @binding.eval 'caller'
    lines = lines
      .reverse
      .reject do |line|
        line.match self.class::filter
      end.map &self.class::formatter

    if (lines_count.is_a?(Numeric) or lines_count.match /\d+/) and
        lines.count > lines_count.to_i
      ["Latest #{lines_count} lines: (`bt all` for full tracing)"] +
      lines.last(lines_count.to_i)
    else
      lines
    end
  end

  def print(lines_count)
    puts build(lines_count || PryMoves::Backtrace::lines_count)
  end

end