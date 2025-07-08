require 'mmi/constants'
require 'mmi/property_attributes'
require 'mmi/asset'
require 'mmi/install_record'

module Mmi
	class AssetsProcessor
		prepend PropertyAttributes
		
		property :profile_dir,              default: Mmi::Constants.minecraft_dir
		property :items,       type: Asset, default: []
		
		def install
			InstallRecord.new.tap do |install_record|
				self.items.each do |asset|
					if asset.enabled
						asset.install(install_record)
					end
				end
				
				install_record.install(self.profile_dir)
			end
		end
	end
end
