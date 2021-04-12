module Mmi
	module Modloaders
		class FabricProcessor
			attr_reader :options
			
			attr_reader :version
			attr_reader :install_type
			attr_reader :mcversion
			attr_reader :install_dir
			
			def initialize(options)
				@options = options
				
				@version      = options['version'          ]
				@install_type = options['install_type'     ]
				@mcversion    = options['minecraft_version']
				@install_dir  = options['install_dir'      ] || Mmi.minecraft_dir
				
				if self.version
					if self.install_type
						if ['client', 'server'].include?(self.install_type)
							if self.mcversion
								# Pass.
							else
								Mmi.fail! 'Missing "modloader.minecraft_version".'
							end
						else
							Mmi.fail! %Q{Invalid "modloader.install_type". Expecting "client" or "server", got #{self.install_type.inspect}.}
						end
					else
						Mmi.fail! 'Missing "modloader.install_type".'
					end
				else
					Mmi.fail! 'Missing "modloader.version".'
				end
			end
			
			def installer_uri
				"https://maven.fabricmc.net/net/fabricmc/fabric-installer/#{self.version}/fabric-installer-#{self.version}.jar"
			end
			
			def installer_sha512sum_uri
				"#{installer_uri}.sha512"
			end
			
			def installer_path
				File.join(Mmi.cache_dir, "fabric-installer-#{self.version}.jar")
			end
			
			def absolute_install_dir
				File.expand_path(self.install_dir)
			end
			
			def download_installer
				Mmi.info "Downloading fabric-installer version #{self.version.inspect}."
				
				begin
					FileUtils.mkdir_p(Mmi.cache_dir)
					
					expected_hexdigest = URI.open(installer_sha512sum_uri).read
					
					if !File.exists?(installer_path) || expected_hexdigest != Digest::SHA512.hexdigest(File.read(installer_path))
						stream = URI.open(installer_uri)
						
						IO.copy_stream(stream, installer_path)
						
						actual_hexdigest = Digest::SHA512.hexdigest(File.read(installer_path))
						
						if expected_hexdigest == actual_hexdigest
							# Pass.
						else
							Mmi.fail! "Expected fabric installer to have SHA512 sum #{expected_hexdigest.inspect} but received #{actual_hexdigest.inspect}."
						end
					else
						Mmi.info 'Using cached fabric-installer.'
					end
				rescue OpenURI::HTTPError => e
					Mmi.fail! %Q{Error when requesting fabric installer. Maybe "modloader.version" == #{version.inspect} is invalid.\n#{e.inspect}}
				end
			end
			
			def run_installer
				FileUtils.mkdir_p(absolute_install_dir)
				
				if system('java', '-jar', installer_path, 'client', '-dir', absolute_install_dir, '-noprofile', '-mcversion', self.mcversion)
					# Pass.
				else
					Mmi.fail! 'Failed to install Fabric modloader.'
				end
			end
			
			def install
				download_installer
				run_installer
			end
		end
	end
end