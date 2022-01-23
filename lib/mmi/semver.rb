module Mmi
	class Semver
		attr_accessor :major
		attr_accessor :minor
		attr_accessor :patch
		
		def initialize(major, minor, patch)
			self.major = major
			self.minor = minor
			self.patch = patch
		end
		
		def self.parse(s)
			if (m = /\A(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\z/.match(s.strip))
				new(m[:major].to_i, m[:minor].to_i, m[:patch].to_i)
			else
				raise "Version string not in valid format: #{s.inspect}"
			end
		end
	end
end
