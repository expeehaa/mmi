module Mmi
	module Modloader
		class Fabric
			attr_reader :options
			
			attr_reader :version
			attr_reader :install_type
			attr_reader :mcversion
			attr_reader :install_dir
			attr_reader :download_mc
			
			def initialize(options)
				@options = options
				
				@version      = options['version'           ]
				@install_type = options['install_type'      ]
				@mcversion    = options['minecraft_version' ]
				@install_dir  = options['install_dir'       ] || Mmi.minecraft_dir
				@download_mc  = options['download_minecraft'] || false
				
				if self.version
					if self.install_type
						if ['client', 'server'].include?(self.install_type)
							if self.mcversion
								if [true, false].include?(self.download_mc)
									# Pass.
								else
									raise Mmi::InvalidAttributeError, %Q{Invalid "modloader.download_minecraft". Expecting true or false, got #{self.download_mc.inspect}.}
								end
							else
								raise Mmi::MissingAttributeError, 'Missing "modloader.minecraft_version".'
							end
						else
							raise Mmi::InvalidAttributeError, %Q{Invalid "modloader.install_type". Expecting "client" or "server", got #{self.install_type.inspect}.}
						end
					else
						raise Mmi::MissingAttributeError, 'Missing "modloader.install_type".'
					end
				else
					raise Mmi::MissingAttributeError, 'Missing "modloader.version".'
				end
			end
			
			def base_uri
				'https://maven.fabricmc.net/net/fabricmc/fabric-installer'
			end
			
			def installer_uri
				File.join(base_uri, self.version, "fabric-installer-#{self.version}.jar")
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
					Mmi::CachedDownload.download_cached(installer_uri, installer_path, sha512_uri: installer_sha512sum_uri)
				rescue OpenURI::HTTPError => e
					Mmi.fail! %Q{Error when requesting fabric installer. Maybe "modloader.version" == #{version.inspect} is invalid.\n#{e.inspect}}
				end
			end
			
			def run_installer
				FileUtils.mkdir_p(absolute_install_dir)
				
				if system('java', '-jar', installer_path, self.install_type, '-dir', absolute_install_dir, '-noprofile', '-mcversion', self.mcversion, self.download_mc ? '-downloadMinecraft' : '')
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