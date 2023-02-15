require File.join(File.dirname(__FILE__), 'lib/rack/sassc/version')

Gem::Specification.new do |s|
  s.name          = 'rack-sassc'
  s.version       = Rack::SassC::VERSION
  s.summary       = "Rack middleware for SassC"
  s.description   = "Rack middleware for SassC which process sass/scss files when in development environment."
  s.authors       = ["Mickael Riga"]
  s.email         = ["mig@mypeplum.com"]
  s.files         = `git ls-files -z`.split("\x0")
  s.homepage      = "https://github.com/mig-hub/rack-sassc"
  s.license       = 'MIT'
  s.require_paths = ["lib"]

  s.add_dependency 'rack', '>= 2.0'
  s.add_dependency 'sassc', '~> 2.0'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'rack-test', '~> 2'
  s.add_development_dependency "rake"
  s.add_development_dependency "bundler"
end

