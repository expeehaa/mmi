require 'fileutils'
require 'open-uri'

require 'mmi/modrinth_api'
require 'mmi/property_attributes'
require 'mmi/content_hash/sha512'

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
				(@cached_mod_versions ||= {})[{loader: loader, game_version: game_version}] ||= Mmi::ModrinthApi.project_versions(self.name, loader: loader, game_version: game_version)
			end
			
			def api_version_file
				cached_mod_versions.select do |version|
					version['name'] == self.version
				end.map do |version|
					version['files']
				end.flatten(1).select do |files|
					files['filename'] == self.version_file
				end.first
			end
			
			def download_url
				api_version_file['url'].gsub(/ /, '%20')
			end
			
			def install(install_record)
				filepath = File.join(install_dir, self.filename || self.version_file)
				
				install_record.add(download_url, filepath, content_hash: Mmi::ContentHash::Sha512.new(api_version_file['hashes']['sha512']))
			end
			
			def display_name
				"https://modrinth.com/mod/#{name}"
			end
		end
	end
end
