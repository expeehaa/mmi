require 'fileutils'
require 'nokogiri'

require 'mmi/install_utils'
require 'mmi/constants'
require 'mmi/property_attributes'

module Mmi
	module Modloader
		class Fabric
			prepend Mmi::PropertyAttributes
			
			property :version
			property :install_type,                                              validate: :validate_install_type
			property :minecraft_version
			property :install_dir,        default: Mmi::Constants.minecraft_dir
			property :download_minecraft, default: false,                        validate: :validate_download_minecraft
			
			def self.allowed_install_types
				%w[
					client
					server
				]
			end
			
			def self.validate_install_type(value, errors)
				if !allowed_install_types.include?(value)
					errors << %Q{modloader "install_type" must be one of #{allowed_install_types.map(&:inspect).join(', ')}}
				end
			end
			
			def self.validate_download_minecraft(value, errors)
				if ![true, false].include?(value)
					errors << 'modloader "download_minecraft" must be true or false'
				end
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
					Mmi::InstallUtils.download_cached(installer_uri, installer_path, sha512_uri: installer_sha512sum_uri)
				rescue OpenURI::HTTPError => e
					Mmi.fail! %Q{Error when requesting fabric installer. Maybe "modloader.version" == #{version.inspect} is invalid.\n#{e.inspect}}
				end
			end
			
			def run_installer
				FileUtils.mkdir_p(absolute_install_dir)
				
				if system('java', '-jar', installer_path, self.install_type, '-dir', absolute_install_dir, '-noprofile', '-mcversion', self.minecraft_version, self.download_minecraft ? '-downloadMinecraft' : '')
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
					Mmi::InstallUtils.download_cached(metadata_uri, metadata_path, sha512_uri: metadata_sha512sum_uri)
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
