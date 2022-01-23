Warbler::Config.new do |config|
	# Features: additional options controlling how the jar is built.
	# Currently the following features are supported:
	# - *gemjar*: package the gem repository in a jar file in WEB-INF/lib
	# - *executable*: embed a web server and make the war executable
	# - *runnable*: allows to run bin scripts e.g. `java -jar my.war -S rake -T`
	# - *compiled*: compile .rb files to .class files
	config.features = %w[gemjar executable]
	config.includes = FileList['mmi.gemspec']
	
	# Bundler support is built-in. If Warbler finds a Gemfile in the
	# project directory, it will be used to collect the gems to bundle
	# in your application. If you wish to explicitly disable this
	# functionality, uncomment here.
	# config.bundler = false
	
	config.jar_name       = "mmi-#{Mmi::VERSION}"
	config.jar_extension  = 'jar'
	config.autodeploy_dir = 'jar/'
	
	# Determines if ruby files in supporting gems will be compiled.
	# Ignored unless compile feature is used.
	config.compile_gems = false
	
	# When set it specify the bytecode version for compiled class files
	# config.bytecode_version = '1.8'
end
