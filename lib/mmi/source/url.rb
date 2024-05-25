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
			
			def install(dir)
				install_dir = File.expand_path(self.install_dir, dir)
				filepath    = File.join(install_dir, self.filename || File.basename(download_uri.path))
				
				Mmi.info "Downloading #{url.inspect} into #{filepath.inspect}."
				
				FileUtils.mkdir_p(install_dir)
				
				begin
					stream = download_uri.open
					
					IO.copy_stream(stream, filepath)
				rescue OpenURI::HTTPError => e
					Mmi.fail! "Error when requesting asset.\n#{e.inspect}"
				end
			end
			
			def display_name
				url
			end
		end
	end
end
