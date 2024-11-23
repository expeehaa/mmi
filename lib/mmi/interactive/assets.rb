require 'mmi/github_api'
require 'mmi/source/github'

module Mmi
	module Interactive
		module Assets
			def update_assets
				window = main_window.subwin(0, 0, 0, 0)
				window.keypad true
				
				current_index = 0
				
				loop do
					window.box('|', '-')
					
					processor.assets.items.each_with_index do |asset, index|
						window.attron(Curses.color_pair(current_index == index ? 1 : 0)) do
							window.setpos(2+index, 2)
							window.addstr(asset.source.display_name)
						end
					end
					
					window.refresh
					
					case window.getch
						when 259
							current_index = (current_index-1) % processor.assets.items.size
						when 258
							current_index = (current_index+1) % processor.assets.items.size
						when 'e', 10
							update_asset_source_version(processor.assets.items[current_index].source)
						when 'a'
							add_asset
						when 'q'
							break
					end
				end
			ensure
				window.erase
				window.refresh
				window.close
			end
			
			def add_asset
				if (source = create_source)
					asset = Mmi::Asset.parse({
						'source' => source.to_h,
					})
					
					self.processor.assets['items'].push(asset.to_h)
					self.processor.assets.parse!
				else
					false
				end
			end
			
			def create_source
				source_type = prompt_choice('Choose a source type.', [
					['GitHub',   :github  ],
					['Modrinth', :modrinth],
					['URL',      :url     ],
				])
				
				source =
					case source_type
						when :github
							options = {
								'type'     => 'github',
								'asset_id' => 0,
							}
							
							options['owner'      ] = prompt_text('Owner of the source repository').strip
							options['repo'       ] = prompt_text('Name of the source repository').strip
							options['install_dir'] = prompt_text('Asset install directory', default: 'mods').strip
							options['filename'   ] = prompt_text('Asset file name (leave empty for default)').strip.then do |filename|
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
							
							options['name'       ] = prompt_text('Mod name (as in the Modrinth URL)').strip
							options['install_dir'] = prompt_text('Asset install directory', default: 'mods').strip
							options['filename'   ] = prompt_text('Asset file name (leave empty for default)').strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options.compact!
							
							Mmi::Source::Modrinth.parse(options)
						when :url
							options = {
								'type' => 'url',
							}
							
							options['install_dir'] = prompt_text('Asset install directory', default: 'mods').strip
							options['filename'   ] = prompt_text('Asset file name (leave empty for default)').strip.then do |filename|
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
						github_releases = Mmi::GithubApi.client.releases("#{source.owner}/#{source.repo}").select do |release|
							release.assets.any?
						end.map do |release|
							[release.name, release]
						end
						
						if github_releases.any?
							github_release = prompt_choice('Choose a release.', github_releases)
							
							release_asset = prompt_choice('Choose an asset.', github_release.assets.map {|a| [a.name, a] })
							source.update_properties!({
								release:  nil,
								file:     nil,
								asset_id: release_asset.id,
							})
							
							true
						else
							prompt_choice("No GitHub releases found!", [['Ok', nil]])
							
							false
						end
					when Mmi::Source::Modrinth
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
						available_mod_versions = source.cached_mod_versions(**version_filter_parameters).select do |version|
							version['files'].any?
						end.map do |version|
							["#{version['name']} (for game versions #{version['game_versions'].join('/')})", version]
						end
						
						if available_mod_versions.any?
							mod_version = prompt_choice('Choose a version.', available_mod_versions)
							
							version_file = mod_version['files'].map do |file|
								[file['filename'], file]
							end.then do |options|
								prompt_choice('Choose a version file.', options)
							end
							
							source.update_properties!({
								version:      mod_version['name'],
								version_file: version_file['filename'],
							})
							
							true
						else
							prompt_choice("No mod versions for Minecraft #{processor.modloader.minecraft_version} available!", [['Ok', nil]])
							
							false
						end
					when Mmi::Source::Url
						url = prompt_text('URL to download from', default: source.url).strip
						
						source.update_properties!({url: url})
				end
			end
		end
	end
end
