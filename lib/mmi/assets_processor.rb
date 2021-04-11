require_relative 'sources/github_source'

module Mmi
	class AssetsProcessor
		attr_reader :profile_dir
		attr_reader :assets
		
		def initialize(profile_dir, assets)
			@profile_dir = profile_dir
			@assets      = assets
		end
		
		def install_asset(asset, index)
			source = asset['source']
			
			if source
				type = source['type']
				
				case type
				when 'github'
					Sources::GithubSource.new(source).install(self.profile_dir)
				else
					Mmi.fail! %Q{Invalid "source.type" in asset #{index.inspect}: #{type.inspect}}
				end
			else
				Mmi.fail! %Q{Missing "source" in asset #{index.inspect}.}
			end
		end
		
		def install
			assets.each_with_index do |asset, index|
				install_asset(asset, index)
			end
		end
	end
end