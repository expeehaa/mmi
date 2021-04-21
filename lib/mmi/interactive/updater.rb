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
							['modloader'             , :modloader   ],
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
					when :modloader
						update_modloader
					when :assets
						update_assets
					when :quit_save
						file_path = CLI::UI::Prompt.ask('Filename', default: self.file_path, is_file: true)
						yaml      = self.processor.options.to_yaml
						
						File.write(File.expand_path(file_path, Dir.pwd), yaml)
						break
					when :quit_discard
						break
					else
						raise 'Consider yourself lucky, you found a bug.'
					end
				end
			end
			
			def update_modloader
				choice = CLI::UI::Prompt.ask('What do you want to do?') do |handler|
					[
						(["Update current modloader #{self.processor.modloader['name']}", :update_current] unless self.processor.parsed_modloader.is_a?(Mmi::Modloader::None)),
						['quit'                                                         , :quit          ],
					].each do |name, result|
						handler.option(name) do |s|
							result
						end
					end
				end
				
				case choice
				when :update_current
					update_modloader_current
				when :quit
					# Pass.
				else
					raise 'Consider yourself lucky, you found a bug.'
				end
			end
			
			def update_modloader_current
				ml = self.processor.parsed_modloader
				
				case ml
				when Mmi::Modloader::None
					CLI::UI.puts('There is currently no modloader set, please choose one first.', color: CLI::UI::Color::RED)
				when Mmi::Modloader::Fabric
					while true
						choice = CLI::UI::Prompt.ask('What do you want to update?') do |handler|
							[
								['Installer version'  , :version     ],
								['Minecraft version'  , :mc_version  ],
								['Download Minecraft?', :download_mc ],
								['Install directory'  , :install_dir ],
								['Install type'       , :install_type],
								['quit'               , :quit        ],
							].each do |name, result|
								handler.option(name) do |s|
									result
								end
							end
						end
						
						case choice
						when :version
							choice2 = CLI::UI::Prompt.ask('Choose a fabric installer version') do |handler|
								ml.available_versions.sort.reverse.each do |v|
									handler.option(v, &:itself)
								end
								
								handler.option('quit', &:to_sym)
							end
							
							case choice2
							when :quit
								# Pass.
							else
								ml.version = choice2
							end
						when :mc_version
							choice2 =
								begin
									CLI::UI::Prompt.ask('Which Minecraft version do you need?')
								rescue Interrupt
									:quit
								end
							
							case choice2
							when :quit
								# Pass.
							else
								ml.mcversion = choice2
							end
						when :download_mc
							choice2 =
								begin
									CLI::UI::Prompt.confirm('Download minecraft when installing the modloader? (Ctrl+C for no change)', default: ml.download_mc)
								rescue Interrupt
									:quit
								end
							
							case choice2
							when :quit
								# Pass.
							else
								ml.download_mc = choice2
							end
						when :install_dir
							choice2 =
								begin
									CLI::UI::Prompt.ask("In which directory should the modloader be installed? ", is_file: true)
								rescue Interrupt
									:quit
								end
							
							case choice2
							when :quit
								# Pass.
							else
								ml.install_dir = choice2.strip.empty? ? nil : choice2
							end
						when :install_type
							choice2 = CLI::UI::Prompt.ask('What type of installation do you want?') do |handler|
								[
									'client',
									'server',
								].each do |type|
									handler.option(type, &:itself)
								end
								
								handler.option('quit', &:to_sym)
							end
							
							case choice2
							when :quit
								# Pass.
							else
								ml.install_type = choice2
							end
						when :quit
							break
						else
							raise 'Consider yourself lucky, you found a bug.'
						end
					end
				else
					CLI::UI.puts("Modloader #{self.processor.modloader['name']} is not supported.", color: CLI::UI::Color::RED)
				end
			end
			
			def update_assets
				while true
					assets = processor.parsed_assets.parsed_assets
					
					choice = CLI::UI::Prompt.ask('Which asset do you want to change?') do |handler|
						assets.each do |asset|
							handler.option(asset.display_name) do |s|
								asset
							end
						end
						
						handler.option('add' , &:to_sym)
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
						}
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
						self.processor.assets ||= []
						
						self.processor.assets.push(options)
						self.processor.parsed_assets.parsed_assets.push(source)
						
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
