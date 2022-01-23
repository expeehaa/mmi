require 'digest'
require 'fileutils'
require 'open-uri'

module Mmi
	module CachedDownload
		class << self;
			def open_cached(path, sha512: nil)
				if File.exist?(path)
					File.open(path).tap do |f|
						if !sha512 || sha512 == Digest::SHA512.hexdigest(f.read)
							f.seek(0)
							f
						else
							nil
						end
					end
				else
					nil
				end
			end
			
			def download(uri, sha512: nil)
				URI.parse(uri).open.tap do |stream|
					if sha512
						actual_sha512 = Digest::SHA512.hexdigest(stream.read)
						
						if sha512 == actual_sha512
							stream.seek(0)
						else
							Mmi.fail! "Expected download to have SHA512 sum #{expected_hexdigest.inspect} but received #{actual_sha512.inspect}."
						end
					end
				end
			end
			
			def download_cached(uri, download_path, sha512_uri: nil)
				ensure_cache_dir_exists!
				
				expected_hexdigest = URI.parse(sha512_uri).open.read
				cached_file        = open_cached(download_path, sha512: expected_hexdigest)
				
				if !cached_file
					stream = download(uri, sha512: expected_hexdigest)
					
					IO.copy_stream(stream, download_path)
				else
					Mmi.info "Using cached version of #{uri.inspect} from #{download_path.inspect}."
				end
			end
			
			private
			
			def ensure_cache_dir_exists!
				FileUtils.mkdir_p(Mmi.cache_dir)
			end
		end
	end
end
