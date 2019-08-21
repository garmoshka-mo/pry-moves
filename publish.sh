gem build pry-moves.gemspec
gem push pry-moves-`ruby -e 'require "./lib/pry-moves/version.rb"; puts PryMoves::VERSION'`.gem
