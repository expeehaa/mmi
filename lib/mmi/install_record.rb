require 'psych'

require 'mmi/content_hash/base'

module Mmi
	class InstallRecord
		RecordEntry = Struct.new(:url, :content_hash)
		
		RECORD_FILE = '.mmi_install_record'.freeze
		
		def initialize
			@record = {}
		end
		
		def add(url, relative_path, content_hash:)
			raise 'content_hash must be nil or an instance of Mmi::ContentHash::Base' unless content_hash.nil? || content_hash.is_a?(Mmi::ContentHash::Base)
			
			@record[relative_path] = RecordEntry.new(url, content_hash)
		end
		
		def install(dir)
			@record.each do |relative_path, entry|
				target_file = File.expand_path(relative_path, dir)
				
				Mmi.info "Downloading #{entry.url.inspect} into #{target_file.inspect}."
				
				begin
					Mmi::InstallUtils.download_to_file(entry.url, target_file)
				rescue OpenURI::HTTPError => e
					Mmi.fail! "Error when requesting asset.\n#{e.inspect}"
				end
			end
			
			File.write(File.expand_path(RECORD_FILE, dir), to_yaml)
		end
		
		def to_yaml
			Psych.dump(@record)
		end
	end
end
