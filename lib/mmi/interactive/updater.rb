module Mmi
	module Interactive
		class Updater
			attr_accessor :processor
			attr_accessor :file_path
			
			def initialize(processor, file_path=nil)
				self.processor = processor
				self.file_path = file_path
			end
			
			def run!
				while true
					to_update = CLI::UI::Prompt.ask('What do you want to update?') do |handler|
						[
							['assets'                , :assets      ],
							['quit & save changes'   , :quit_save   ],
							['quit & discard changes', :quit_discard],
						].each do |name, result|
							handler.option(name) do |s|
								result
							end
						end
					end
					
					case to_update
					when :assets
						update_assets
					when :quit_save
						file_path = CLI::UI::Prompt.ask('Filename', default: self.file_path, is_file: true)
						yaml      = self.processor.content.to_yaml
						
						File.write(File.expand_path(file_path, Dir.pwd), yaml)
						break
					when :quit_discard
						break
					else
						raise 'Consider yourself lucky, you found a bug.'
					end
				end
			end
			
			def update_assets
				while true
					assets = processor.assets.assets
					
					choice = CLI::UI::Prompt.ask('Which asset do you want to change?') do |handler|
						assets.each do |asset|
							handler.option(asset.display_name) do |s|
								asset
							end
						end
						
						handler.option('quit', &:to_sym)
					end
					
					case choice
					when :quit
						break
					else
						update_asset(choice)
					end
				end
			end
			
			def update_asset(asset)
				case asset
				when Mmi::Source::Github
					releases = ::Github::Client::Repos::Releases.new.list(owner: asset.owner, repo: asset.repo, per_page: 100)
					
					release = CLI::UI::Prompt.ask('Choose a release.') do |handler|
						releases.select do |release|
							release.assets.any?
						end.each do |release|
							handler.option(release.name) do |s|
								release
							end
						end
						
						handler.option('quit', &:to_sym)
					end
					
					case release
					when :quit
						false
					else
						release_asset = CLI::UI::Prompt.ask('Choose an asset.') do |handler|
							release.assets.each do |a|
								handler.option(a.name) do |s|
									a
								end
							end
							
							handler.option('quit', &:to_sym)
						end
						
						case release_asset
						when :quit
							false
						else
							asset.options.delete('release')
							asset.options.delete('file'   )
							
							asset.options['asset_id'] = release_asset.id
							
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
