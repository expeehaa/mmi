require 'mmi/assets_processor'
require 'mmi/modloader/none'
require 'mmi/modloader/fabric'
require 'mmi/property_attributes'
require 'mmi/semver'

module Mmi
	class ModFileProcessor
		prepend PropertyAttributes
		
		property :version,   type: Semver
		property :modloader, type: {field: 'name', types: {'none' => Modloader::None, 'fabric' => Modloader::Fabric}}
		property :assets,    type: AssetsProcessor
		
		def install
			self.modloader.install
			self.assets.install
		end
	end
end
