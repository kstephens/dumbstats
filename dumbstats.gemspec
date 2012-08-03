# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dumbstats/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kurt Stephens"]
  gem.email         = ["ks.ruby@kurtstephens.com"]
  gem.description   = %q{Collect data, generate stats, draw histograms, send to Graphite, do stuff in Ruby. }
  gem.summary       = %q{Simple stats collection}
  gem.homepage      = "https://github.com/kstephens/dumbstats"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dumbstats"
  gem.require_paths = ["lib"]
  gem.version       = Dumbstats::VERSION
end
