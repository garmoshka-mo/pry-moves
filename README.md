# pry-moves

_An execution control add-on for [Pry][pry]._

* Install: `gem 'pry-moves'`
* For non-rails (without auto-require), add to your script: `require 'pry-moves'`

## Commands:

* `n` - **next** line in current frame, including block lines (moving to next line goes as naturally expected)
* `s` - **step** into function execution
  * `s func_name` - step into first method called by name `func_name`
* `f` - **finish** execution of current frame (block or method) and stop at next line on higher level
* `c` - **continue**
* `bt` - show latest 5 lines from backtrace
  * `bt 10` - latest 10 lines
  * `bt all` - full backtrace
  * `bt > foo` - write backtrace to file `log/backtrace_foo.log`
* `up`/`down`/`top`/`bottom` - move over call stack
  * `up +` - move up, including vapid frames (block callers, hidden frames)
  * `up pattern` - move up till first frame which method name or file position in format `folder/script.rb:12` matches regexp pattern
* `debug some_method(some_param)` - call `some_method(some_param)` and interactively step into it. This way you can virtually "step back" by executing previous pieces of code from current method
* `watch variable` - display variable's value on each step
* `!` - exit


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

Here is default configuration, you can override it:

```ruby
PryMoves::Backtrace::lines_count = 5
PryMoves::Backtrace::filter =
  /(\/gems\/|\/rubygems\/|\/bin\/|\/lib\/ruby\/|\/pry-moves\/)/
```

## Threads, helpers

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
```

## Contributors

* Gopal Patel ([@nixme](https://github.com/nixme))
* John Mair ([@banister](https://github.com/banister))
* Conrad Irwin ([@ConradIrwin](https://github.com/ConradIrwin))
* Benjamin R. Haskell ([@benizi](https://github.com/benizi))
* Jason R. Clark ([@jasonrclark](https://github.com/jasonrclark))
* Ivo Anjo ([@ivoanjo](https://github.com/ivoanjo))

Patches and bug reports are welcome. Just send a [pull request][pullrequests] or
file an [issue][issues]. [Project changelog][changelog].

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
