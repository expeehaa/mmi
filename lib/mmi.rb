require_relative 'mmi/mod_file_processor'

module Mmi
	VERSION = '0.1.0'
	
	MMI_CACHE_DIR = File.join(Dir.home, '.cache', 'mmi')
	MINECRAFT_DIR = File.join(Dir.home, '.minecraft')
	
	def self.cache_dir
		MMI_CACHE_DIR
	end
	
	def self.minecraft_dir
		MINECRAFT_DIR
	end
	
	def self.debug(text)
		if ENV['MMI_ENV']=='dev'
			puts text
		end
	end
	
	def self.info(text)
		puts text
	end
	
	def self.fail!(text)
		STDERR.puts text
		Kernel.exit 1
	end
end