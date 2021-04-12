require_relative 'source/github'

module Mmi
	class AssetsProcessor
		attr_reader :profile_dir
		attr_reader :assets
		
		def initialize(profile_dir, assets)
			@profile_dir = profile_dir
			
			assets ||= []
			
			if assets.is_a?(Array)
				@assets = assets.map.with_index do |asset, index|
					source = asset['source']
					
					if source
						type = source['type']
						
						case type
						when 'github'
							Source::Github.new(source)
						else
							Mmi.fail! %Q{Invalid "source.type" in asset #{index.inspect}: #{type.inspect}}
						end
					else
						Mmi.fail! %Q{Missing "source" in asset #{index.inspect}.}
					end
				end
			else
				Mmi.fail! %Q{Invalid "assets": expected Array or nothing, got #{self.assets.inspect}.}
			end
		end
		
		def install
			assets.each do |asset|
				asset.install(self.profile_dir)
			end
		end
	end
end