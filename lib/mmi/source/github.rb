module Mmi
	module Source
		class Github
			attr_reader :options
			
			attr_reader :owner
			attr_reader :repo
			attr_reader :install_dir
			
			attr_reader :release
			attr_reader :file
			
			def initialize(options)
				@options = options
				
				@owner       = options['owner'      ]
				@repo        = options['repo'       ]
				@release     = options['release'    ]
				@file        = options['file'       ]
				@install_dir = options['install_dir']
				
				if self.owner
					if self.repo
						if self.release
							if self.file
								if self.install_dir
									# Pass.
								else
									raise Mmi::MissingAttributeError, 'Missing "source.install_dir" from asset.'
								end
							else
								raise Mmi::MissingAttributeError, 'Missing "source.file" from asset.'
							end
						else
							raise Mmi::MissingAttributeError, 'Missing "source.release" from asset.'
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