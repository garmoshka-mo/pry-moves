module PryMoves

  class AddSuffix < Pry::ClassCommand

    group 'Input and Output'
    description "Continue traversing of last object in history."

    banner <<-'BANNER'
      Usage: .method | 123 | :hash_key

      Continue traversing of last object in history

      E.g. `orders` will list array, then `3` will enter `orders[3]`, then `.price` will enter `orders[3].price`
    BANNER

    def process(cmd)
      last_cmd = Pry.history.to_a[-1]
      cmd = "#{last_cmd}#{wrap_suffix(cmd)}"
      _pry_.pager.page "    > #{cmd}\n"
      _pry_.eval cmd
    end

    private

    def wrap_suffix(cmd)
      cmd
    end

  end

  class Method < AddSuffix
    match(/^(\..+)$/)
  end

  class ArgumentCall < AddSuffix
    match(/^(\(.*\).*)/)
  end

  class ArrayIndex < AddSuffix
    match(/^(\d+)$/)

    def wrap_suffix(cmd)
      "[#{cmd}]"
    end
  end

  class ArrayCall < AddSuffix
    match(/^(\[\d+\].*)/)
  end

  class HashKey < AddSuffix
    match(/^(:\w+)$/)

    def wrap_suffix(cmd)
      "[#{cmd}]"
    end
  end


end

SUFFIX_COMMANDS = [
  PryMoves::Method,
  PryMoves::ArgumentCall,
  PryMoves::ArrayIndex,
  PryMoves::ArrayCall,
  PryMoves::HashKey
]

SUFFIX_COMMANDS.each do |cmd|
  Pry::Commands.add_command(cmd)
end

Pry::History.class_eval do

  def <<(line)
    return if ["!"].include? line
    return if SUFFIX_COMMANDS.any? do |cls|
      line.match(cls.match)
    end
    push line
  end

end
