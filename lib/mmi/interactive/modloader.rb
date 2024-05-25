require 'cli/ui'

require 'mmi/modloader/fabric'
require 'mmi/modloader/none'

module Mmi
	module Interactive
		module Modloader
			def update_modloader
				choice = CLI::UI::Prompt.ask('What do you want to do?') do |handler|
					[
						(["Update current modloader #{self.processor.modloader['name']}", :update_current] unless self.processor.modloader.is_a?(Mmi::Modloader::None)),
						['quit',                                                          :quit          ],
					].each do |name, result|
						handler.option(name) do
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
				ml = self.processor.modloader
				
				case ml
					when Mmi::Modloader::None
						CLI::UI.puts('There is currently no modloader set, please choose one first.', color: CLI::UI::Color::RED)
					when Mmi::Modloader::Fabric
						loop do
							choice = CLI::UI::Prompt.ask('What do you want to update?') do |handler|
								[
									['Installer version',   :version           ],
									['Minecraft version',   :minecraft_version ],
									['Download Minecraft?', :download_minecraft],
									['Install directory',   :install_dir       ],
									['Install type',        :install_type      ],
									['quit',                :quit              ],
								].each do |name, result|
									handler.option(name) do
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
											ml.update_properties!({version: choice2})
									end
								when :minecraft_version
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
											ml.update_properties!({minecraft_version: choice2})
									end
								when :download_minecraft
									choice2 =
										begin
											CLI::UI::Prompt.confirm('Download minecraft when installing the modloader? (Ctrl+C for no change)', default: ml.download_minecraft)
										rescue Interrupt
											:quit
										end
									
									case choice2
										when :quit
											# Pass.
										else
											ml.update_properties!({download_minecraft: choice2})
									end
								when :install_dir
									choice2 =
										begin
											CLI::UI::Prompt.ask('In which directory should the modloader be installed? ', is_file: true)
										rescue Interrupt
											:quit
										end
									
									case choice2
										when :quit
											# Pass.
										else
											ml.update_properties!({install_dir: choice2.strip.empty? ? nil : choice2})
									end
								when :install_type
									choice2 = CLI::UI::Prompt.ask('What type of installation do you want?') do |handler|
										ml.allowed_install_types.each do |type|
											handler.option(type, &:itself)
										end
										
										handler.option('quit', &:to_sym)
									end
									
									case choice2
										when :quit
											# Pass.
										else
											ml.update_properties!({install_type: choice2})
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
		end
	end
end
