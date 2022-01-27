require 'json'
require 'open-uri'

module Mmi
	module ModrinthApi
		BASE_URL = URI('https://api.modrinth.com/api/v1/')
		
		class << self
			def mod(name)
				JSON.parse((BASE_URL + "mod/#{CGI.escape(name)}").open.read)
			end
			
			def mod_versions(mod_id)
				JSON.parse((BASE_URL + "mod/#{mod_id}/version").open.read)
			end
		end
	end
end
