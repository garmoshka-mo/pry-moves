if @command[:action] == :ababa
  puts 'catch debug'


  set_trace_func (
                     Proc.new { |event, file, line, id, binding_, classname|
                       #if file == '(pry)'
                       #unless file.match /\/gems\/|\/ruby\//
                       printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
                       if event=='line' and file == 'sand.rb' and line != 47
                         set_trace_func nil
                         Pry.start(binding_, @pry_start_options)
                       end
                     })

  puts "CALLER:\n#{caller.join "\n"}\n"

  #Pry.start(command[:binding], @pry_start_options)
  return return_value
end

TracePoint.new(:line) {|tp|p [tp.lineno, tp.event]}.enable

set_trace_func proc { |event, file, line, id, binding, classname|
                 printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
               }


set_trace_func proc { |event, file, line, id, binding, classname|
                 printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname	unless file.match /\/gems\/|\/ruby\//
               }


set_trace_func proc { |event, file, line, id, binding, classname|
                 printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname if file == '(pry)'
               }






