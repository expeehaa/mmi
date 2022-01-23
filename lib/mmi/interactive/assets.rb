require 'cli/ui'
require 'github_api'

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
							update_asset(choice)
					end
				end
			end
			
			def add_asset
				source_type = CLI::UI::Prompt.ask('Choose a source type.') do |handler|
					[
						'github',
					].each do |type|
						handler.option(type, &:to_sym)
					end
					
					handler.option('quit', &:to_sym)
				end
				
				case source_type
					when :quit
						false
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
						
						source = Mmi::Source::Github.new(options['source'])
						
						if update_asset(source)
							self.processor.parsed_assets.items.push(options)
							self.processor.parsed_assets.parsed_items.push(source)
							
							true
						else
							CLI::UI.puts('Aborting asset addition. No change will be made.', color: CLI::UI::Color::RED)
							
							false
						end
				end
			end
			
			def update_asset(asset)
				case asset
					when Mmi::Source::Github
						github_releases = ::Github::Client::Repos::Releases.new.list(owner: asset.owner, repo: asset.repo, per_page: 100)
						
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
					else
						CLI::UI.puts('This asset cannot be updated.', color: CLI::UI::Color::RED)
						
						false
				end
			end
		end
	end
end
