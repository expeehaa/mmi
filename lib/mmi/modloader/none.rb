module Mmi
	module Modloader
		class None
			def initialize
				# Not installing anything requires no configuration or setup.
			end
			
			def self.parse(*)
				new
			end
			
			def install
				# Nothing to do.
			end
		end
	end
end
