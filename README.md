### Using [**pry-byebug**][pry-byebug] and not happy with commands behavior? We recommend this project instead

# pry-moves

_An execution control add-on for [Pry][pry]._


## Commands:

* `n` - **next** line in current frame, including block lines (moving to next line goes as naturally expected)
* `s` - **step** into function execution
  * `s func_name` - steps into first method called by name `func_name`
* `f` - **finish** execution of current frame and stop at next line on higher level
* `c` - **continue**
* `bt` - backtrace
* `!` - exit


## Examples

To use, invoke `pry` normally:

```ruby
def some_method
  binding.pry          # Execution will stop here.
  puts 'Hello, World!' # Run 'step' or 'next' in the console to move here.
end
```

## Technical info

`pry-moves` is not yet thread-safe, so only use in single-threaded environments.

Rudimentary support for [`pry-remote`][pry-remote] (>= 0.1.1) is also included.
Ensure `pry-remote` is loaded or required before `pry-moves`. For example, in a
`Gemfile`:

```ruby
gem 'pry'
gem 'pry-remote'
gem 'pry-moves'
```

Please note that debugging functionality is implemented through
[`set_trace_func`][set_trace_func], which imposes a large performance
penalty.

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
