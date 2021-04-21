module Mmi
	module CachedDownload
		class << self;
			def download_cached(uri, download_path, sha512_uri: nil)
				ensure_cache_dir_exists!
				
				expected_hexdigest = URI.open(sha512_uri).read
				
				if !File.exists?(download_path) || expected_hexdigest != Digest::SHA512.hexdigest(File.read(download_path))
					stream           = URI.open(uri)
					actual_hexdigest = Digest::SHA512.hexdigest(stream.read)
					
					if expected_hexdigest == actual_hexdigest
						stream.seek(0)
					else
						Mmi.fail! "Expected download to have SHA512 sum #{expected_hexdigest.inspect} but received #{actual_hexdigest.inspect}."
					end
					
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