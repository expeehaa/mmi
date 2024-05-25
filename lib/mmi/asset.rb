require 'mmi/property_attributes'
require 'mmi/source/github'
require 'mmi/source/modrinth'
require 'mmi/source/url'

module Mmi
	class Asset
		prepend Mmi::PropertyAttributes
		
		property :source, type: {field: 'type', types: {'github' => Source::Github, 'modrinth' => Source::Modrinth, 'url' => Source::Url}}
		
		def install(dir)
			source.install(dir)
		end
	end
end
