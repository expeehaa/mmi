require 'fileutils'
require 'open-uri'

require 'mmi/github_api'
require 'mmi/property_attributes'

module Mmi
	module Source
		class Github
			prepend Mmi::PropertyAttributes
			
			property :owner
			property :repo
			property :install_dir
			property :filename, required: false
			
			property :asset_id, conflicts: %w[release file]
			property :release,  conflicts: 'asset_id', requires: 'file'
			property :file,     conflicts: 'asset_id', requires: 'release'
			
			# TODO: Ensure that either :asset_id or [:release, :file] is given.
			
			def repository_url
				"https://github.com/#{self.owner}/#{self.repo}"
			end
			
			def cached_asset_response
				@cached_asset_response ||= Mmi::GithubApi.client.release_asset("/repos/#{self.owner}/#{self.repo}/releases/assets/#{self.asset_id}")
			end
			
			def download_url
				if self.asset_id
					cached_asset_response.browser_download_url
				else
					"#{repository_url}/releases/download/#{release}/#{file}"
				end
			end
			
			def install(dir)
				install_dir = File.expand_path(self.install_dir, dir)
				filepath    = File.join(install_dir, self.filename || (self.asset_id ? cached_asset_response.name : self.file))
				
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
				repository_url
			end
		end
	end
end
