require 'cli/ui'

require 'mmi/github_api'
require 'mmi/source/github'

module Mmi
	module Interactive
		module Assets
			def update_assets
				loop do
					assets = processor.assets.items
					
					choice = CLI::UI::Prompt.ask('Which asset do you want to change?') do |handler|
						assets.each do |asset|
							handler.option(asset.source.display_name) do
								asset.source
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
							update_asset_source_version(choice)
					end
				end
			end
			
			def add_asset
				if (source = create_source)
					asset = Mmi::Asset.parse({
						'source' => source.to_h,
					})
					
					self.processor.assets['items'].push(asset.to_h)
					self.processor.assets.parse!
				else
					CLI::UI.puts('Aborting asset addition. No change will be made.')
					
					false
				end
			end
			
			def create_source
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
				
				source =
					case source_type
						when :quit
							return false
						when :github
							options = {
								'type'     => 'github',
								'asset_id' => 0,
							}
							
							options['owner'      ] = CLI::UI::Prompt.ask('Who is the owner of the source repository?').strip
							options['repo'       ] = CLI::UI::Prompt.ask('What is the name of the source repository?').strip
							options['install_dir'] = CLI::UI::Prompt.ask('In which directory should the asset be placed?', default: 'mods').strip
							options['filename'   ] = CLI::UI::Prompt.ask('Under which filename should the asset be saved? (leave empty for release asset name)', allow_empty: true).strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options.compact!
							
							Mmi::Source::Github.parse(options)
						when :modrinth
							options = {
								'type'         => 'modrinth',
								'version'      => '0',
								'version_file' => '0',
							}
							
							options['name'       ] = CLI::UI::Prompt.ask('What is the name of the mod in the Modrinth URL?').strip
							options['install_dir'] = CLI::UI::Prompt.ask('In which directory should the asset be placed?', default: 'mods').strip
							options['filename'   ] = CLI::UI::Prompt.ask('Under which filename should the asset be saved? (leave empty for release asset name)', allow_empty: true).strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options.compact!
							
							Mmi::Source::Modrinth.parse(options)
						when :url
							options = {
								'type' => 'url',
							}
							
							options['install_dir'] = CLI::UI::Prompt.ask('In which directory should the asset be placed?', default: 'mods').strip
							options['filename'   ] = CLI::UI::Prompt.ask('Under which filename should the asset be saved? (leave empty for release asset name)', allow_empty: true).strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options.compact!
							
							Mmi::Source::Url.parse(options)
					end
				
				if update_asset_source_version(source)
					source
				else
					nil
				end
			end
			
			def update_asset_source_version(source)
				case source
					when Mmi::Source::Github
						github_releases = Mmi::GithubApi.client.releases("#{source.owner}/#{source.repo}")
						
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
										source.update_properties!({
											release:  nil,
											file:     nil,
											asset_id: release_asset.id,
										})
										
										true
								end
						end
					when Mmi::Source::Modrinth
						mod_version = CLI::UI::Prompt.ask('Choose a version.') do |handler|
							version_filter_parameters =
								case processor.modloader
									when Mmi::Modloader::Fabric
										{
											loader:       'fabric',
											game_version: processor.modloader.minecraft_version,
										}
									else
										{}
								end
							
							source.cached_mod_versions(**version_filter_parameters).select do |version|
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
										source.update_properties!({
											version:      mod_version['name'],
											version_file: version_file['filename'],
										})
										
										true
								end
						end
					when Mmi::Source::Url
						url = CLI::UI::Prompt.ask('What is the URL of the file that should be downloaded?', default: source.url).strip
						
						source.update_properties!({url: url})
					else
						CLI::UI.puts('This asset cannot be updated.', color: CLI::UI::Color::RED)
						
						false
				end
			end
		end
	end
end
