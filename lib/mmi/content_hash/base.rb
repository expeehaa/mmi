module Mmi
	module ContentHash
		class Base
			def match_file?(file_path)
				raise NotImplementedError
			end
		end
	end
end
