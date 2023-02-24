require 'json'
require 'open-uri'

module Mmi
	module ModrinthApi
		BASE_URL = URI('https://api.modrinth.com/v2/')
		
		class << self
			def project_versions(mod_slug)
				JSON.parse((BASE_URL + "project/#{mod_slug}/version").open.read)
			end
		end
	end
end
