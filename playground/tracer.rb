
def trace_events
  set_trace_func (
  proc { |event, file, line, id, binding, classname|
   #next unless line.between? 56, 61
   printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
  })
end