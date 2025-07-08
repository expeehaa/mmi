require 'mmi/property_attributes'
require 'mmi/source/github'
require 'mmi/source/modrinth'
require 'mmi/source/url'

module Mmi
	class Asset
		prepend Mmi::PropertyAttributes
		
		property :source, type: {field: 'type', types: {'github' => Source::Github, 'modrinth' => Source::Modrinth, 'url' => Source::Url}}
		property :enabled, default: true, validate: :validate_enabled
		
		def install(install_record)
			source.install(install_record)
		end
		
		def self.validate_enabled(value, errors)
			if ![true, false].include?(value)
				errors << 'asset "enabled" must be true or false'
			end
		end
	end
end
