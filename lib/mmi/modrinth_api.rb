require 'json'
require 'open-uri'

module Mmi
	module ModrinthApi
		BASE_URL = URI('https://api.modrinth.com/v2/')
		
		class << self
			def project_versions(mod_slug, loader: nil, game_version: nil)
				JSON.parse((BASE_URL + "project/#{mod_slug}/version?#{URI.encode_www_form(loaders: (%Q{["#{loader}"]} if loader), game_versions: (%Q{["#{game_version}"]} if game_version))}").open.read)
			end
		end
	end
end
