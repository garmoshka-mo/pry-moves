module PryMoves::Painter

  class Canvas < String

    def <<(text)
      if length > 2000
        super("... (cut)")
        throw :cut
      end
      super
    end

  end

  def self.colorize(obj)
    colored_str = Canvas.new
    i = obj.inspect
    obj = obj.class if i.is_a?(String) && i.start_with?("#<")
    catch (:cut) do
      Pry::ColorPrinter.pp obj, colored_str
    end
    colored_str.chomp
  rescue => e
    "⛔️ Inspect error: #{e}\n" +
      "#{e.backtrace.first(3).join("\n")}"
  end

end