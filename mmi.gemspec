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
	
	spec.metadata['rubygems_mfa_required'] = 'true'
	
	# Pessimistic guess, versions below may work as well.
	spec.required_ruby_version = '>= 3.0'
	
	spec.add_dependency 'nokogiri', '~> 1.11'
	spec.add_dependency 'octokit',  '~> 8.1'
	spec.add_dependency 'faraday-retry' # FIXME: octokit prints an annoying error message without this gem, see https://github.com/octokit/octokit.rb/issues/1567.
	spec.add_dependency 'curses',   '~> 1.4.7'
end
