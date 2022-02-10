require 'cli/ui'

require 'mmi/github_api'
require 'mmi/source/github'

module Mmi
	module Interactive
		module Assets
			def update_assets
				loop do
					assets = processor.parsed_assets.parsed_items
					
					choice = CLI::UI::Prompt.ask('Which asset do you want to change?') do |handler|
						assets.each do |asset|
							handler.option(asset.display_name) do
								asset
							end
						end
						
						handler.option('add',  &:to_sym)
						handler.option('quit', &:to_sym)
					end
					
					case choice
						when :quit
							break
						when :add
							add_asset
						else
							update_asset_version(choice)
					end
				end
			end
			
			def add_asset
				source_type = CLI::UI::Prompt.ask('Choose a source type.') do |handler|
					%w[
						github
						modrinth
						url
					].each do |type|
						handler.option(type, &:to_sym)
					end
					
					handler.option('quit', &:to_sym)
				end
				
				opts, source =
					case source_type
						when :quit
							return false
						when :github
							options = {
								'source' => {
									'type'     => 'github',
									'asset_id' => 0,
								},
							}
							
							options['source']['owner'      ] = CLI::UI::Prompt.ask('Who is the owner of the source repository?').strip
							options['source']['repo'       ] = CLI::UI::Prompt.ask('What is the name of the source repository?').strip
							options['source']['install_dir'] = CLI::UI::Prompt.ask('In which directory should the asset be placed?', default: 'mods').strip
							options['source']['filename'   ] = CLI::UI::Prompt.ask('Under which filename should the asset be saved? (leave empty for release asset name)', allow_empty: true).strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options['source'].compact!
							
							[options, Mmi::Source::Github.new(options['source'])]
						when :modrinth
							options = {
								'source' => {
									'type'         => 'modrinth',
									'version'      => '0',
									'version_file' => '0',
								},
							}
							
							options['source']['name'       ] = CLI::UI::Prompt.ask('What is the name of the mod in the Modrinth URL?').strip
							options['source']['install_dir'] = CLI::UI::Prompt.ask('In which directory should the asset be placed?', default: 'mods').strip
							options['source']['filename'   ] = CLI::UI::Prompt.ask('Under which filename should the asset be saved? (leave empty for release asset name)', allow_empty: true).strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options['source'].compact!
							
							[options, Mmi::Source::Modrinth.new(options['source'])]
						when :url
							options = {
								'source' => {
									'type' => 'url',
									'url'  => '',
								},
							}
							
							options['source']['install_dir'] = CLI::UI::Prompt.ask('In which directory should the asset be placed?', default: 'mods').strip
							options['source']['filename'   ] = CLI::UI::Prompt.ask('Under which filename should the asset be saved? (leave empty for release asset name)', allow_empty: true).strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options['source'].compact!
							
							[options, Mmi::Source::Url.new(options['source'])]
					end
				
				if update_asset_version(source)
					self.processor.parsed_assets.items.push(opts)
					self.processor.parsed_assets.parsed_items.push(source)
					
					true
				else
					CLI::UI.puts('Aborting asset addition. No change will be made.', color: CLI::UI::Color::RED)
					
					false
				end
			end
			
			def update_asset_version(asset)
				case asset
					when Mmi::Source::Github
						github_releases = Mmi::GithubApi.client.releases("#{asset.owner}/#{asset.repo}")
						
						github_release = CLI::UI::Prompt.ask('Choose a release.') do |handler|
							github_releases.select do |release|
								release.assets.any?
							end.each do |release|
								handler.option(release.name) do
									release
								end
							end
							
							handler.option('quit', &:to_sym)
						end
						
						case github_release
							when :quit
								false
							else
								release_asset = CLI::UI::Prompt.ask('Choose an asset.') do |handler|
									github_release.assets.each do |a|
										handler.option(a.name) do
											a
										end
									end
									
									handler.option('quit', &:to_sym)
								end
								
								case release_asset
									when :quit
										false
									else
										asset.release = nil
										asset.file    = nil
										
										asset.asset_id = release_asset.id
										
										true
								end
						end
					when Mmi::Source::Modrinth
						mod_version = CLI::UI::Prompt.ask('Choose a version.') do |handler|
							asset.cached_mod_versions.select do |version|
								version['files'].any?
							end.each do |version|
								handler.option("#{version['name']} (for game versions #{version['game_versions'].join('/')})") do
									version
								end
							end
							
							handler.option('quit', &:to_sym)
						end
						
						case mod_version
							when :quit
								false
							else
								version_file = CLI::UI::Prompt.ask('Choose a version file.') do |handler|
									mod_version['files'].each do |file|
										handler.option(file['filename']) do
											file
										end
									end
									
									handler.option('quit', &:to_sym)
								end
								
								case version_file
									when :quit
										false
									else
										asset.version      = mod_version['name']
										asset.version_file = version_file['filename']
										
										true
								end
						end
					when Mmi::Source::Url
						asset.url = CLI::UI::Prompt.ask('What is the URL of the file that should be downloaded?', default: asset.url).strip
					else
						CLI::UI.puts('This asset cannot be updated.', color: CLI::UI::Color::RED)
						
						false
				end
			end
		end
	end
end
