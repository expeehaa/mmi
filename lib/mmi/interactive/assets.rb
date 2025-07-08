require 'mmi/github_api'
require 'mmi/source/github'

module Mmi
	module Interactive
		class Assets
			def initialize(processor)
				@processor = processor
			end
			
			def show!
				row_proc = proc do
					@processor.assets.items.map do |asset|
						case asset.source
							when Mmi::Source::Modrinth
								[asset.source.display_name, asset.source.version, asset.source.version_file]
							when Mmi::Source::Github
								[asset.source.display_name, *(asset.source.asset_id.nil? ? [asset.source.release, asset.source.file] : asset.source.asset_id)]
							when Mmi::Source::Url
								[asset.source.display_name]
							else
								[asset.source.display_name]
						end
					end
				end
				
				keybindings = {
					10  => ['Update selected asset.', ->    { update_asset_source_version(@processor.assets.items[it].source) }],
					'a' => ['Add new asset.',         ->(_) { add_asset                                                       }],
					'd' => ['Delete selected asset.', ->    { delete_asset(it)                                                }],
				}
				
				Mmi::Curses::Utils.show_table_window!(row_proc, keybindings)
			end
			
			def add_asset
				if (source = create_source)
					asset = Mmi::Asset.parse({
						'source' => source.to_h,
					})
					
					@processor.assets['items'].push(asset.to_h)
					@processor.assets.parse!
				else
					false
				end
			end
			
			def create_source
				source_type = Mmi::Curses::Utils.prompt_choice('Choose a source type.', [
					['Modrinth', :modrinth],
					['GitHub',   :github  ],
					['URL',      :url     ],
				])
				
				source =
					case source_type
						when :github
							options = {
								'type'     => 'github',
								'asset_id' => 0,
							}
							
							options['owner'      ] = Mmi::Curses::Utils.prompt_text('Owner of the source repository').strip
							options['repo'       ] = Mmi::Curses::Utils.prompt_text('Name of the source repository').strip
							options['install_dir'] = Mmi::Curses::Utils.prompt_text('Asset install directory', default: 'mods').strip
							options['filename'   ] = Mmi::Curses::Utils.prompt_text('Asset file name (leave empty for default)').strip.then do |filename|
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
							
							options['name'       ] = Mmi::Curses::Utils.prompt_text('Mod name (as in the Modrinth URL)').strip
							options['install_dir'] = Mmi::Curses::Utils.prompt_text('Asset install directory', default: 'mods').strip
							options['filename'   ] = Mmi::Curses::Utils.prompt_text('Asset file name (leave empty for default)').strip.then do |filename|
								filename == '' ? nil : filename
							end
							
							options.compact!
							
							Mmi::Source::Modrinth.parse(options)
						when :url
							options = {
								'type' => 'url',
								'url'  => '',
							}
							
							options['install_dir'] = Mmi::Curses::Utils.prompt_text('Asset install directory', default: 'mods').strip
							options['filename'   ] = Mmi::Curses::Utils.prompt_text('Asset file name (leave empty for default)').strip.then do |filename|
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
							github_release = Mmi::Curses::Utils.prompt_choice('Choose a release.', github_releases)
							
							release_asset = Mmi::Curses::Utils.prompt_choice('Choose an asset.', github_release.assets.map {|a| [a.name, a] })
							source.update_properties!({
								release:  nil,
								file:     nil,
								asset_id: release_asset.id,
							})
							
							true
						else
							Mmi::Curses::Utils.prompt_choice("No GitHub releases found!", [['Ok', nil]])
							
							false
						end
					when Mmi::Source::Modrinth
						version_filter_parameters =
							case @processor.modloader
								when Mmi::Modloader::Fabric
									{
										loader:       'fabric',
										game_version: @processor.modloader.minecraft_version,
									}
								else
									{}
							end
						begin
							available_mod_versions = source.cached_mod_versions(**version_filter_parameters).select do |version|
								version['files'].any?
							end.map do |version|
								["#{version['name']} (for game versions #{version['game_versions'].join('/')})", version]
							end
							
							if available_mod_versions.any?
								mod_version = Mmi::Curses::Utils.prompt_choice('Choose a version.', available_mod_versions)
								
								version_file = mod_version['files'].map do |file|
									[file['filename'], file]
								end.then do |options|
									Mmi::Curses::Utils.prompt_choice('Choose a version file.', options)
								end
								
								source.update_properties!({
									version:      mod_version['name'],
									version_file: version_file['filename'],
								})
								
								true
							else
								Mmi::Curses::Utils.prompt_choice("No mod versions for Minecraft #{@processor.modloader.minecraft_version} available!", [['Ok', nil]])
								
								false
							end
						rescue OpenURI::HTTPError => e
							Mmi::Curses::Utils.prompt_choice("Error retrieving mod information.", [['Ok', nil]])

							false
						end
					when Mmi::Source::Url
						url = Mmi::Curses::Utils.prompt_text('URL to download from', default: source.url).strip
						
						source.update_properties!({url: url})
				end
			end
			
			def delete_asset(index)
				@processor.assets['items'].delete_at(index)
				@processor.assets.parse!
			end
		end
	end
end
