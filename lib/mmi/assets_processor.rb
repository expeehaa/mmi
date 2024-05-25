require 'mmi/constants'
require 'mmi/property_attributes'
require 'mmi/asset'

module Mmi
	class AssetsProcessor
		prepend PropertyAttributes
		
		property :profile_dir,              default: Mmi::Constants.minecraft_dir
		property :items,       type: Asset, default: []
		
		def install
			self.items.each do |asset|
				asset.install(self.profile_dir)
			end
		end
	end
end
