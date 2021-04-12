module Mmi
	module Source
		class Github
			attr_reader :options
			
			attr_reader :owner
			attr_reader :repo
			attr_reader :install_dir
			attr_reader :filename
			
			attr_reader :asset_id
			attr_reader :release
			attr_reader :file
			
			def initialize(options)
				@options = options
				
				@owner       = options['owner'      ]
				@repo        = options['repo'       ]
				@asset_id    = options['asset_id'   ]
				@release     = options['release'    ]
				@file        = options['file'       ]
				@install_dir = options['install_dir']
				@filename    = options['filename'   ]
				
				if self.owner
					if self.repo
						if self.install_dir
							if self.asset_id
								# Pass.
							else
								if self.release
									if self.file
										# Pass.
									else
										raise Mmi::MissingAttributeError, 'Missing "source.file" from asset because "source.asset_id" is not provided.'
									end
								else
									raise Mmi::MissingAttributeError, 'Missing "source.release" from asset because "source.asset_id" is not provided.'
								end
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
				@asset_get ||= ::Github::Client::Repos::Releases::Assets.new.get(owner: self.owner, repo: self.repo, id: self.asset_id)
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
					stream = URI.open(download_url)
					
					IO.copy_stream(stream, filepath)
				rescue OpenURI::HTTPError => e
					Mmi.fail! %Q{Error when requesting asset.\n#{e.inspect}}
				end
			end
			
			def display_name
				repository_url
			end
		end
	end
end