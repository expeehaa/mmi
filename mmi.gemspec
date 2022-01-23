require File.expand_path('lib/mmi/version', __dir__)

Gem::Specification.new do |spec|
	spec.name          = 'mmi'
	spec.version       = Mmi::VERSION
	spec.authors       = ['expeehaa']
	spec.email         = ['expeehaa@outlook.com']
	spec.license       = 'GPL-3.0-only'
	spec.summary       = 'Program to install minecraft modloaders, mods and other assets through a single config file.'
	spec.homepage      = 'https://github.com/expeehaa/mmi'
	
	spec.files         = Dir['lib/**/*.rb', 'exe/*', 'README.adoc', 'LICENSE']
	spec.bindir        = 'exe'
	spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
	spec.require_paths = ['lib']
	
	# Pessimistic guess, versions below may work as well.
	spec.required_ruby_version = '>= 3.0'
	
	spec.add_dependency 'cli-ui'    , '~> 1.5.0'
	spec.add_dependency 'github_api', '~> 0.19'
	spec.add_dependency 'nokogiri'  , '~> 1.11'
	
	spec.add_development_dependency 'pry'    , '~> 0.13'
	spec.add_development_dependency 'rake'   , '~> 13.0'
	spec.add_development_dependency 'rspec'  , '~> 3.10'
	spec.add_development_dependency 'rubocop'
	spec.add_development_dependency 'rubocop-rspec'
	spec.add_development_dependency 'warbler', '~> 2.0'
end
