require 'octokit'

module Mmi
	module GithubApi
		class << self
			def client
				@client ||= Octokit::Client.new
			end
		end
	end
end
