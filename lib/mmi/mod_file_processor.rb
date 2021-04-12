require_relative 'modloaders/none_processor'
require_relative 'modloaders/fabric_processor'
require_relative 'assets_processor'

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
							Modloaders::NoneProcessor.new(ml)
						when 'fabric'
							Modloaders::FabricProcessor.new(ml)
						else
							Mmi.fail! %Q{Unkown modloader #{ml['name'].inspect}.}
						end
					else
						Modloaders::NoneProcessor.new
					end
					
					@assets = AssetsProcessor.new(self.profile_dir, content['assets'])
				else
					Mmi.fail! %Q{Config file specified "version" #{version}, but MMI is at #{lib_version}.}
				end
			else
				Mmi.fail! 'Missing "version".'
			end
		end
		
		def install
			self.modloader.install
			self.assets.install
		end
	end
end