# lib = File.expand_path('../lib', __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name     = "simple-service"
  gem.version  = File.read("VERSION")

  gem.authors  = [ "radiospiel" ]
  gem.email    = "eno@radiospiel.org"
  gem.homepage = "http://github.com/radiospiel/simple-service"
  gem.summary  = "Pretty simple and somewhat abstract service description"

  gem.description = "Pretty simple and somewhat abstract service description"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths =  %w(lib)

  # executables are used for development purposes only
  gem.executables   = []

  gem.required_ruby_version = '~> 2.5'

  gem.add_dependency "expectation", "~> 1"
  gem.add_dependency "simple-immutable", "~> 1", ">= 1.1"
end
