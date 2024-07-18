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
			old_record = self.class.parse_record_file(dir) || {}
			
			@record.each do |relative_path, entry|
				target_file = File.expand_path(relative_path, dir)
				
				if old_record[relative_path] != entry || (File.exist?(target_file) && !entry.content_hash&.match_file?(target_file))
					Mmi.info "Downloading #{entry.url.inspect} into #{target_file.inspect}."
					
					begin
						Mmi::InstallUtils.download_to_file(entry.url, target_file, entry.content_hash)
					rescue OpenURI::HTTPError => e
						Mmi.fail! "Error when requesting asset.\n#{e.inspect}"
					end
				else
					Mmi.info "Skipping #{entry.url.inspect} because it is already present at #{target_file.inspect}."
				end
				
				old_record.delete(relative_path)
			end
			
			old_record.each do |relative_path, _|
				target_file = File.expand_path(relative_path, dir)
				
				File.delete(target_file) if File.exist?(target_file)
			end
			
			File.write(File.expand_path(RECORD_FILE, dir), to_yaml)
		end
		
		def to_yaml
			Psych.dump(@record)
		end
		
		def self.parse_record_file(dir)
			record_file = File.expand_path(RECORD_FILE, dir)
			
			if File.exist?(record_file)
				parsed_record = Psych.unsafe_load_file(record_file)
				
				unless !parsed_record.is_a?(Hash) || parsed_record.keys.any?{|k| !k.is_a?(String)} && parsed_record.values.any?{|v| !v.is_a?(Record)}
					parsed_record
				else
					Mmi.warn("Found invalid install record at #{record_file}. The file will be ignored.")
					nil
				end
			else
				nil
			end
		end
	end
end
