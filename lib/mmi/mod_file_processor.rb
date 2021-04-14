require 'mmi/modloader/none'
require 'mmi/modloader/fabric'
require 'mmi/assets_processor'

module Mmi
	class ModFileProcessor
		attr_reader :content
		
		attr_reader :version
		attr_reader :profile_dir
		
		attr_reader :modloader
		attr_reader :assets
		
		def initialize(content)
			@content = content
			
			@version     = content['version'    ]
			@profile_dir = content['profile_dir'] || Mmi.minecraft_dir
			
			version     = SemVer.parse(self.version)
			lib_version = SemVer.parse(Mmi::VERSION)
			
			if self.version
				if version.major <= lib_version.major
					if version.minor > lib_version.minor
						Mmi.warn %Q{Config file specified "version" #{version}, but MMI is at #{lib_version}. Some features might not be supported.}
					end
					
					ml         = content['modloader']
					@modloader = if ml
						case ml['name']
						when 'none'
							Modloader::None.new(ml)
						when 'fabric'
							Modloader::Fabric.new(ml)
						else
							raise Mmi::InvalidAttributeError, %Q{Unkown modloader #{ml['name'].inspect}.}
						end
					else
						Modloader::None.new
					end
					
					@assets = AssetsProcessor.new(self.profile_dir, content['assets'])
				else
					raise Mmi::InvalidAttributeError, %Q{Config file specified "version" #{version}, but MMI is at #{lib_version}.}
				end
			else
				raise Mmi::MissingAttributeError, 'Missing "version".'
			end
		end
		
		def install
			self.modloader.install
			self.assets.install
		end
	end
end
