require 'fileutils'
require 'open-uri'

require 'mmi/github_api'
require 'mmi/option_attributes'

module Mmi
	module Source
		class Github
			include Mmi::OptionAttributes
			
			opt_accessor :owner
			opt_accessor :repo
			opt_accessor :install_dir
			opt_accessor :filename
			
			opt_accessor :asset_id
			opt_accessor :release
			opt_accessor :file
			
			def initialize(options)
				@options = options
				
				parse!
			end
			
			def parse!
				if self.owner
					if self.repo
						if self.install_dir
							if self.asset_id
								# Pass.
							elsif self.release
								if self.file
									# Pass.
								else
									raise Mmi::MissingAttributeError, 'Missing "source.file" from asset because "source.asset_id" is not provided.'
								end
							else
								raise Mmi::MissingAttributeError, 'Missing "source.release" from asset because "source.asset_id" is not provided.'
							end
						else
							raise Mmi::MissingAttributeError, 'Missing "source.install_dir" from asset.'
						end
					else
						raise Mmi::MissingAttributeError, 'Missing "source.repo" from asset.'
					end
				else
					raise Mmi::MissingAttributeError, 'Missing "source.owner" from asset.'
				end
			end
			
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
