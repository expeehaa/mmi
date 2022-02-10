require 'fileutils'
require 'open-uri'

require 'mmi/option_attributes'

module Mmi
	module Source
		class Url
			include Mmi::OptionAttributes
			
			opt_accessor :url
			opt_accessor :install_dir
			opt_accessor :filename
			
			def initialize(options)
				@options = options
				
				parse!
			end
			
			def parse!
				if self.url
					if self.install_dir
						# Pass.
					else
						raise Mmi::MissingAttributeError, 'Missing "source.install_dir" from asset.'
					end
				else
					raise Mmi::MissingAttributeError, 'Missing "source.name" from asset.'
				end
			end
			
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
