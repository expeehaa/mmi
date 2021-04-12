require_relative 'modloaders/none_processor'
require_relative 'modloaders/fabric_processor'
require_relative 'assets_processor'

module Mmi
	class ModFileProcessor
		attr_reader :content
		
		attr_reader :version
		attr_reader :profile_dir
		attr_reader :assets
		
		attr_reader :modloader
		
		def initialize(content)
			@content = content
			
			@version     = content['version'    ]
			@profile_dir = content['profile_dir'] || Mmi.minecraft_dir
			@assets      = content['assets'     ]
			
			version     = SemVer.parse(self.version)
			lib_version = SemVer.parse(Mmi::VERSION)
			
			if self.version
				if version.major <= lib_version.major
					if version.minor > lib_version.minor
						Mmi.warn %Q{Config file specified "version" #{version}, but MMI is at #{lib_version}. Some features might not be supported.}
					end
					
					if self.assets.nil? || self.assets.is_a?(Array)
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
					else
						Mmi.fail! %Q{Invalid "assets": expected Array or nothing, got #{self.assets.inspect}.}
					end
				else
					Mmi.fail! %Q{Config file specified "version" #{version}, but MMI is at #{lib_version}.}
				end
			else
				Mmi.fail! 'Missing "version".'
			end
		end
		
		def install_assets
			AssetsProcessor.new(self.profile_dir, self.assets).install
		end
		
		def install
			self.modloader.install
			install_assets
		end
	end
end