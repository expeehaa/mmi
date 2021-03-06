require 'mmi/assets_processor'
require 'mmi/modloader/none'
require 'mmi/modloader/fabric'
require 'mmi/option_attributes'
require 'mmi/semver'

module Mmi
	class ModFileProcessor
		include OptionAttributes
		
		opt_accessor :version
		opt_accessor :modloader
		opt_accessor :assets
		
		attr_reader :parsed_modloader
		attr_reader :parsed_assets
		
		def initialize(options)
			@options = options
			
			parse!
		end
		
		def parse!
			version     = Semver.parse(self.version)
			lib_version = Semver.parse(Mmi::VERSION)
			
			if self.version
				if version.major <= lib_version.major
					if version.minor > lib_version.minor
						Mmi.warn %Q(Config file specified "version" #{version}, but MMI is at #{lib_version}. Some features might not be supported.)
					end
					
					ml = self.modloader
					@parsed_modloader =
						if ml
							case ml['name']
								when 'none'
									Modloader::None.new(ml)
								when 'fabric'
									Modloader::Fabric.new(ml)
								else
									raise Mmi::InvalidAttributeError, "Unkown modloader #{ml['name'].inspect}."
							end
						else
							Modloader::None.new
						end
					
					
					if self.assets
						if self.assets.is_a?(Hash)
							@parsed_assets = AssetsProcessor.new(self.assets)
						else
							raise Mmi::InvalidAttributeError, %Q(Invalid "assets": expected Hash but received #{self.assets.inspect})
						end
					else
						raise Mmi::MissingAttributeError, 'Missing "assets".'
					end
				else
					raise Mmi::InvalidAttributeError, %Q(Config file specified "version" #{version}, but MMI is at #{lib_version}.)
				end
			else
				raise Mmi::MissingAttributeError, 'Missing "version".'
			end
		end
		
		def install
			self.parsed_modloader.install
			self.parsed_assets.install
		end
	end
end
