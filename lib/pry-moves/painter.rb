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
    catch (:cut) do
      Pry::ColorPrinter.pp obj, colored_str
    end
    colored_str.chomp
  end

end