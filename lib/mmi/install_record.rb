module Mmi
	class InstallRecord
		RecordEntry = Struct.new(:url)
		
		def initialize
			@record = {}
		end
		
		def add(url, relative_path)
			@record[relative_path] = RecordEntry.new(url)
		end
		
		def install(dir)
			@record.each do |relative_path, entry|
				target_file = File.expand_path(relative_path, dir)
				
				Mmi.info "Downloading #{entry.url.inspect} into #{target_file.inspect}."
				
				FileUtils.mkdir_p(File.dirname(target_file))
				
				begin
					stream = URI.parse(entry.url).open
					
					IO.copy_stream(stream, target_file)
				rescue OpenURI::HTTPError => e
					Mmi.fail! "Error when requesting asset.\n#{e.inspect}"
				end
			end
		end
	end
end
