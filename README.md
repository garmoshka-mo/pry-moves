# pry-moves

![](https://ruby-gem-downloads-badge.herokuapp.com/pry-moves?type=total)

_An execution control add-on for [Pry][pry]._

* Install: `gem 'pry-moves'`
* For non-rails (without auto-require), add to your script: `require 'pry-moves'`

## Commands:

Documentation for latest version. For [v0.1.12 see documentation here](https://github.com/garmoshka-mo/pry-moves/tree/v0.1.12#commands)

* `n` - **next** line in current frame, including block lines (moving to next line goes as naturally expected)
  * `nn` - **next** line in current frame, skipping block lines
* `s` - **step** into function execution
  * `s method_name` - step into method `method_name` (For example from `User.new.method_name`). Partial name match supported.
  * `s +` - step into function, including hidden frames
* `f` - **finish** execution of current frame (block or method) and stop at next line on higher level
* `c` - **continue**
* `b` - go to next breakpoint (breakpoints currently are methods which contain "debug" in their name)
* `iterate` - go to next iteration of current block
* `g 10` - **goto** line 10
* `bt` - show backtrace, excluding hidden frames
  * `bt +` `bt hidden` - show backtrace including hidden frames
  * `bt a` `bt all` - full backtrace with system and hidden frames
  * `bt 10` - go to backtrace line 10
  * `bt save` - save backtrace to memory
  * `bt diff` - diff with saved backtrace
  * `bt > foo` - write backtrace to file `log/backtrace_foo.log`
* `up`/`down`/`top`/`bottom` - move over call stack
  * `up +` - move up, including vapid frames (block callers, hidden frames)
  * `up pattern` - move up till first frame which method name or file position in format `folder/script.rb:12` matches regexp pattern
* `%` - print current frame of call stack (alias to `whereami`)
* `$` - fully print current function without line numbers
* `debug some_method(some_param)` - call `some_method(some_param)` and interactively step into it. This way you can virtually "step back" by executing previous pieces of code from current method
* `.method` or `123` or `:hash_key` - Continue traversing of last object in history. E.g. `orders` will list array, then `3` will enter `orders[3]`, then `.price` will enter `orders[3].price`
* `watch variable` - display variable's value on each step
* `@` - restart. Set config `PryMoves.reload_rake_tasks = true` to automatically reload rake tasks
* `#` - exit with code 3, can be wrapped in bash script to fully reload ruby scripts
* `!` - exit

Variable & methods names takes precedence over commands. 
So if you have variable named `step`, to execute command `step` type `cmd step` or command's alias, e.g. `s` 

## Examples

To use, invoke `pry` normally:

```ruby
def some_method
  binding.pry          # Execution will stop here.
  puts 'Hello, World!' # Run 'step' or 'next' in the console to move here.
end
```

### Advanced example

<img src="https://user-images.githubusercontent.com/2452269/27320748-37afe7de-55a0-11e7-8b8f-ae05bcb02f37.jpg" width="377">

_Demo class source [here](https://github.com/garmoshka-mo/pry-moves/issues/1)_

## Backtrace and call stack

You can explicitly hide frames from backtrace and call stack by defining `hide_from_stack` variable:

```ruby
def insignificant_method
  hide_from_stack = true
  something_insignificant
  yield
end
```

## Configuration

Here is default configuration, you can reassign it:

```ruby
PryMoves::Backtrace::filter =
  /(\/gems\/|\/rubygems\/|\/bin\/|\/lib\/ruby\/|\/pry-moves\/)/
```

## Threads, helpers

To allow traveling to parent thread, use:

```ruby
pre_callers = binding.callers
Thread.new do
  Thread.current[:pre_callers] = pre_callers
  #...
end
```

`pry-moves` can't stop other threads on `binding.pry`, so they will continue to run.
This makes `pry-moves` not always suitable for debugging of multi-thread projects.

Though you can pause other threads with helper which will suspend execution on current line,
until ongoing debug session will be finished with `continue`:

```ruby
PryMoves.synchronize_threads
```

_For example, you can put it into function which periodically reports status of thread (if you have such)_

Other helpers:
* `PryMoves.open?` - if pry input dialog active. Can be used to suppress output from ongoing parallel threads 

## pry-remote

Rudimentary support for [`pry-remote`][pry-remote] (>= 0.1.1) is also included.
Ensure `pry-remote` is loaded or required before `pry-moves`. For example, in a
`Gemfile`:

```ruby
gem 'pry'
gem 'pry-remote'
gem 'pry-moves'
```

## Performance

Please note that debugging functionality is implemented through
[`set_trace_func`][set_trace_func], which imposes heavy performance penalty while tracing
(while running code within `next`/`step`/`finish` commands).

# Development

## Testing

```
bundle exec rspec

DEBUG=true bundle exec rspec -e 'backtrace should backtrace'
```

## ToDo

* `iterate` - steps in into child sub-block - should skip

## Contributors

* Gopal Patel ([@nixme](https://github.com/nixme))
* John Mair ([@banister](https://github.com/banister))
* Conrad Irwin ([@ConradIrwin](https://github.com/ConradIrwin))
* Benjamin R. Haskell ([@benizi](https://github.com/benizi))
* Jason R. Clark ([@jasonrclark](https://github.com/jasonrclark))
* Ivo Anjo ([@ivoanjo](https://github.com/ivoanjo))

Patches and bug reports are welcome. Just send a [pull request][pullrequests] or
file an [issue][issues]. 

## Acknowledgments

* Gopal Patel's [pry-nav](https://github.com/nixme/pry-nav)
* John Mair's [pry-stack_explorer](https://github.com/pry/pry-stack_explorer)
* Ruby stdlib's [debug.rb][debug.rb]
* [@Mon-Ouie][Mon-Ouie]'s [pry_debug][pry_debug]

[pry]:            http://pryrepl.org/
[pry-remote]:     https://github.com/Mon-Ouie/pry-remote
[set_trace_func]: http://www.ruby-doc.org/core-1.9.3/Kernel.html#method-i-set_trace_func
[pullrequests]:   https://github.com/garmoshka-mo/pry-moves/pulls
[issues]:         https://github.com/garmoshka-mo/pry-moves/issues
[changelog]:      https://github.com/garmoshka-mo/pry-moves/blob/master/CHANGELOG.md
[debug.rb]:       https://github.com/ruby/ruby/blob/trunk/lib/debug.rb
[Mon-Ouie]:       https://github.com/Mon-Ouie
[pry_debug]:      https://github.com/Mon-Ouie/pry_debug
[pry-byebug]:     https://github.com/deivid-rodriguez/pry-byebug
