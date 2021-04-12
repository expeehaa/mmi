module Mmi
	module Source
		class Github
			attr_reader :options
			
			attr_reader :release
			attr_reader :file
			attr_reader :install_dir
			
			attr_reader :owner
			attr_reader :repo
			
			def initialize(options)
				@options = options
				
				repository   = options['repository' ]
				@release     = options['release'    ]
				@file        = options['file'       ]
				@install_dir = options['install_dir']
				
				if repository
					if m = /\A(?<owner>[^\/]+)\/(?<repo>[^\/]+)\z/.match(repository)
						@owner = m[:owner]
						@repo  = m[:repo ]
						
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
						Mmi.fail! %Q{Invalid "source.repository": #{repository.inspect} cannot be interpreted.}
					end
				else
					Mmi.fail! 'Missing "source.repository" from asset.'
				end
			end
			
			def repository_url
				"https://github.com/#{self.owner}/#{self.repo}"
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