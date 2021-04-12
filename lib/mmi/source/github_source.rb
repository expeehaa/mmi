module Mmi
	module Source
		class GithubSource
			attr_reader :options
			
			attr_reader :repository
			attr_reader :release
			attr_reader :file
			attr_reader :install_dir
			
			def initialize(options)
				@options = options
				
				@repository  = options['repository' ]
				@release     = options['release'    ]
				@file        = options['file'       ]
				@install_dir = options['install_dir']
				
				if self.repository
					if self.release
						if self.file
							if self.install_dir
								# Pass.
							else
								Mmi.fail! 'Missing "source.install_dir" from asset.'
							end
						else
							Mmi.fail! 'Missing "source.file" from asset.'
						end
					else
						Mmi.fail! 'Missing "source.release" from asset.'
					end
				else
					Mmi.fail! 'Missing "source.repository" from asset.'
				end
			end
			
			def repository_url
				"https://github.com/#{self.repository}"
			end
			
			def download_url
				"#{repository_url}/releases/download/#{release}/#{file}"
			end
			
			def install(dir)
				install_dir = File.expand_path(self.install_dir, dir)
				filepath    = File.join(install_dir, self.file)
				
				Mmi.info "Downloading #{download_url.inspect} into #{filepath.inspect}."
				
				FileUtils.mkdir_p(install_dir)
				
				begin
					stream = URI.open(download_url)
					
					IO.copy_stream(stream, filepath)
				rescue OpenURI::HTTPError => e
					Mmi.fail! %Q{Error when requesting asset.\n#{e.inspect}}
				end
			end
		end
	end
end