require 'mmi/version'
require 'mmi/mod_file_processor'

module Mmi
	class ValidationError < StandardError; end
	class MissingAttributeError < ValidationError; end
	class InvalidAttributeError < ValidationError; end
	
	def self.debug(text)
		if ENV['MMI_ENV'] == 'dev'
			puts text
		end
	end
	
	def self.info(text)
		puts text
	end
	
	def self.warn(text)
		puts text
	end
	
	def self.fail!(text)
		Kernel.warn text
		Kernel.exit 1
	end
end
