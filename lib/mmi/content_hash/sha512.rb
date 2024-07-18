require 'digest'

require 'mmi/content_hash/base'

module Mmi
	module ContentHash
		class Sha512 < Base
			attr_accessor :hex_digest
			
			def initialize(hex_digest)
				super()
				
				self.hex_digest = hex_digest
			end
			
			def match_file?(file_path)
				Digest::SHA512.hexdigest(File.read(file_path)) == self.hex_digest
			end
			
			def ==(other)
				self.class == other.class && self.hex_digest == other.hex_digest
			end
		end
	end
end
