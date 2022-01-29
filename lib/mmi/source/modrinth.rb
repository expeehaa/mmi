require 'fileutils'
require 'open-uri'

require 'mmi/modrinth_api'
require 'mmi/option_attributes'

module Mmi
	module Source
		class Modrinth
			include Mmi::OptionAttributes
			
			opt_accessor :name
			opt_accessor :version
			opt_accessor :version_file
			
			opt_accessor :install_dir
			opt_accessor :filename
			
			def initialize(options)
				@options = options
				
				parse!
			end
			
			def parse!
				if self.name
					if self.version
						if self.version_file
							if self.install_dir
								# Pass.
							else
								raise Mmi::MissingAttributeError, 'Missing "source.install_dir" from asset.'
							end
						else
							raise Mmi::MissingAttributeError, 'Missing "source.version_file" from asset.'
						end
					else
						raise Mmi::MissingAttributeError, 'Missing "source.version" from asset.'
					end
				else
					raise Mmi::MissingAttributeError, 'Missing "source.name" from asset.'
				end
			end
			
			def cached_mod_id
				@cached_mod_id ||= Mmi::ModrinthApi.mod(self.name)['id']
			end
			
			def cached_mod_versions
				@cached_mod_versions ||= Mmi::ModrinthApi.mod_versions(cached_mod_id)
			end
			
			def download_url
				cached_mod_versions.select do |version|
					version['name'] == self.version
				end.first['files'].select do |files|
					files['filename'] == self.version_file
				end.first['url'].gsub(/ /, '%20')
			end
			
			def install(dir)
				install_dir = File.expand_path(self.install_dir, dir)
				filepath    = File.join(install_dir, self.filename || self.version_file)
				
				Mmi.info "Downloading #{download_url.inspect} into #{filepath.inspect}."
				
				FileUtils.mkdir_p(install_dir)
				
				begin
					stream = URI.parse(download_url).open
					
					IO.copy_stream(stream, filepath)
				rescue OpenURI::HTTPError => e
					Mmi.fail! "Error when requesting asset.\n#{e.inspect}"
				end
			end
			
			def display_name
				"https://modrinth.com/mod/#{name}"
			end
		end
	end
end
