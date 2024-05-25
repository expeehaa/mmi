require 'fileutils'
require 'nokogiri'

require 'mmi/cached_download'
require 'mmi/constants'
require 'mmi/option_attributes'

module Mmi
	module Modloader
		class Fabric
			include Mmi::OptionAttributes
			
			opt_accessor :version
			opt_accessor :install_type
			opt_accessor :mcversion,    'minecraft_version'
			opt_accessor(:install_dir                       ) { Mmi::Constants.minecraft_dir }
			opt_accessor(:download_mc,  'download_minecraft') { false             }
			
			def initialize(options)
				@options = options
				
				parse!
			end
			
			def parse!
				if self.version
					if self.install_type
						if allowed_install_types.include?(self.install_type)
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
			
			def allowed_install_types
				%w[
					client
					server
				]
			end
			
			def base_uri
				'https://maven.fabricmc.net/net/fabricmc/fabric-installer'
			end
			
			def metadata_uri
				File.join(base_uri, 'maven-metadata.xml')
			end
			
			def metadata_sha512sum_uri
				"#{metadata_uri}.sha512"
			end
			
			def metadata_path
				File.join(Mmi::Constants.cache_dir, 'fabric_maven_metadata.xml')
			end
			
			def installer_uri
				File.join(base_uri, self.version, "fabric-installer-#{self.version}.jar")
			end
			
			def installer_sha512sum_uri
				"#{installer_uri}.sha512"
			end
			
			def installer_path
				File.join(Mmi::Constants.cache_dir, "fabric-installer-#{self.version}.jar")
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
			
			def available_versions
				begin
					Mmi::CachedDownload.download_cached(metadata_uri, metadata_path, sha512_uri: metadata_sha512sum_uri)
				rescue OpenURI::HTTPError => e
					Mmi.fail! "Error when requesting available fabric installer versions.\n#{e.inspect}"
				end
				
				xml = File.open(metadata_path) do |f|
					Nokogiri::XML(f)
				end
				
				xml.xpath('/metadata/versioning/versions/version').map(&:inner_html)
			end
		end
	end
end
