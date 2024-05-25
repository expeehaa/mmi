require 'fileutils'
require 'open-uri'

require 'mmi/modrinth_api'
require 'mmi/property_attributes'

module Mmi
	module Source
		class Modrinth
			prepend Mmi::PropertyAttributes
			
			property :name
			property :version
			property :version_file
			property :install_dir
			property :filename, required: false
			
			def cached_mod_versions(loader: nil, game_version: nil)
				(@cached_mod_versions ||= Hash.new)[{loader: loader, game_version: game_version}] ||= Mmi::ModrinthApi.project_versions(self.name, loader: loader, game_version: game_version)
			end
			
			def download_url
				cached_mod_versions.select do |version|
					version['name'] == self.version
				end.map do |version|
					version['files']
				end.flatten(1).select do |files|
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
