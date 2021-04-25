require 'mmi/source/github'

module Mmi
	class AssetsProcessor
		include OptionAttributes
		
		opt_accessor :profile_dir do Mmi.minecraft_dir end
		opt_accessor :items       do []                end
		
		attr_reader :parsed_items
		
		def initialize(options)
			@options = options
			
			if self.items.is_a?(Array)
				@parsed_items = self.items.map.with_index do |asset, index|
					source = asset['source']
					
					if source
						type = source['type']
						
						case type
						when 'github'
							Source::Github.new(source)
						else
							raise Mmi::InvalidAttributeError, %Q{Invalid "source.type" in asset #{index.inspect}: #{type.inspect}}
						end
					else
						raise Mmi::MissingAttributeError, %Q{Missing "source" in asset #{index.inspect}.}
					end
				end
			else
				raise Mmi::InvalidAttributeError, %Q{Invalid "assets": expected Array or nothing, got #{self.items.inspect}.}
			end
		end
		
		def install
			self.parsed_items.each do |asset|
				asset.install(self.profile_dir)
			end
		end
	end
end