require 'digest'
require 'fileutils'
require 'open-uri'

require 'mmi/constants'
require 'mmi/content_hash/base'

module Mmi
	module InstallUtils
		class << self
			def download_to_file(url, target_file, content_hash=nil)
				raise 'content_hash must be nil or an instance of Mmi::ContentHash::Base' unless content_hash.nil? || content_hash.is_a?(Mmi::ContentHash::Base)
				
				FileUtils.mkdir_p(File.dirname(target_file))
				
				stream = URI.parse(url).open
				
				IO.copy_stream(stream, target_file)
				
				raise "Failed to match #{target_file} with #{content_hash.inspect}!" if content_hash && !content_hash.match_file?(target_file)
			end
		end
	end
end
