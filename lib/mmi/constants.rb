module Mmi
	module Constants
		MMI_CACHE_DIR = File.join(Dir.home, '.cache', 'mmi')
		MINECRAFT_DIR = File.join(Dir.home, '.minecraft')
		
		def self.cache_dir
			MMI_CACHE_DIR
		end
		
		def self.minecraft_dir
			MINECRAFT_DIR
		end
	end
end
