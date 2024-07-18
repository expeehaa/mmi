require 'fileutils'
require 'open-uri'

require 'mmi/property_attributes'

module Mmi
	module Source
		class Url
			prepend Mmi::PropertyAttributes
			
			property :url
			property :install_dir
			property :filename, required: false
			
			def download_uri
				@download_uri ||= URI.parse(url)
			end
			
			def install(install_record)
				filepath = File.join(install_dir, self.filename || File.basename(download_uri.path))
				
				install_record.add(url, filepath)
			end
			
			def display_name
				url
			end
		end
	end
end
