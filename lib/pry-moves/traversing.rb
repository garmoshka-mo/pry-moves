module PryMoves

  class Traversing < Pry::ClassCommand

    group 'Input and Output'
    description "Continue traversing of last object in history."

    banner <<-'BANNER'
      Usage: .method | 123 | :hash_key

      Continue traversing of last object in history
    BANNER

    def process(cmd)
      last_cmd = Pry.history.to_a[-2]
      # don't save command to history:
      Pry.history.instance_variable_get(:@history).pop
      cmd = "#{last_cmd}#{wrap_command(cmd)}"
      _pry_.pager.page "    > #{cmd}\n"
      _pry_.eval cmd
    end

    private


  end

  class Method < Traversing
    match(/\.(.+)/)

    def wrap_command(cmd)
      ".#{cmd}"
    end
  end

  class ArrayIndex < Traversing
    match(/(\d+)/)

    def wrap_command(cmd)
      "[#{cmd}]"
    end
  end

  class HashKey < Traversing
    match(/(:\w+)/)

    def wrap_command(cmd)
      "[#{cmd}]"
    end
  end

  Pry::Commands.add_command(PryMoves::Method)
  Pry::Commands.add_command(PryMoves::ArrayIndex)
  Pry::Commands.add_command(PryMoves::HashKey)

end
