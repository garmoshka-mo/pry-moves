module PryMoves

  class Traversing < Pry::ClassCommand

    group 'Input and Output'
    description "Continue traversing of last object in history."

    banner <<-'BANNER'
      Usage: .method | 123 | :hash_key

      Continue traversing of last object in history

      E.g. `orders` will list array, then `3` will enter `orders[3]`, then `.price` will enter `orders[3].price`
    BANNER

    def process(cmd)
      last_cmd = Pry.history.to_a[-1]
      cmd = "#{last_cmd}#{wrap_command(cmd)}"
      _pry_.pager.page "    > #{cmd}\n"
      _pry_.eval cmd
    end

    private


  end

  class Method < Traversing
    match(/^\.(.+)$/)

    def wrap_command(cmd)
      ".#{cmd}"
    end
  end

  class ArrayIndex < Traversing
    match(/^(\d+)$/)

    def wrap_command(cmd)
      "[#{cmd}]"
    end
  end

  class HashKey < Traversing
    match(/^(:\w+)$/)

    def wrap_command(cmd)
      "[#{cmd}]"
    end
  end

  Pry::Commands.add_command(PryMoves::Method)
  Pry::Commands.add_command(PryMoves::ArrayIndex)
  Pry::Commands.add_command(PryMoves::HashKey)

end

Pry::History.class_eval do

  EXCLUDE = [PryMoves::Method, PryMoves::ArrayIndex, PryMoves::HashKey]

  def <<(line)
    return if EXCLUDE.any? do |cls|
      line.match(cls.match)
    end
    push line
  end

end
