require 'mmi/modloader/fabric'
require 'mmi/modloader/none'

module Mmi
	module Interactive
		module Modloader
			def update_modloader
				if self.processor.modloader.is_a?(Mmi::Modloader::Fabric)
					update_modloader_fabric
				else
					false
				end
			end
			
			def update_modloader_fabric
				ml = self.processor.modloader
				
				window = main_window.subwin(0, 0, 0, 0)
				window.keypad true
				
				options = [
					['Update installer version', -> do
						available_installer_versions = ml.available_versions.sort.reverse
						installer_version            = prompt_choice('Choose a fabric installer version', available_installer_versions.map {|v| [v, v]}, initial_index: available_installer_versions.index(ml.version))
						ml.update_properties!({version: installer_version})
					end],
					['Update Minecraft version', -> do
						minecraft_version = prompt_text('Minecraft version', default: ml.minecraft_version)
						ml.update_properties!({minecraft_version: minecraft_version})
					end],
					['Download Minecraft?',      -> do
						download_minecraft = prompt_choice('Download Minecraft when installing?', [['Yes', true], ['No', false]], initial_index: ml.download_minecraft ? 0 : 1)
						ml.update_properties!({download_minecraft: download_minecraft})
					end],
					['Change install directory', -> do
						install_directory = prompt_text('Modloader install directory', default: ml.install_dir)
						ml.update_properties!({install_dir: install_directory.strip.empty? || install_directory == ml.class.registered_properties[:install_dir].default ? nil : install_directory})
					end],
					['Change install type',      -> do
						install_type = prompt_choice('Install type', ml.class.allowed_install_types.map {|t| [t, t]}, initial_index: ml.class.allowed_install_types.index(ml.install_type))
						ml.update_properties!({install_type: install_type})
					end],
				]
				
				current_index = 0
				
				loop do
					window.box('|', '-')
					
					options.each_with_index do |option, index|
						window.attron(Curses.color_pair(current_index == index ? 1 : 0)) do
							window.setpos(2+index, 2)
							window.addstr(option[0])
						end
					end
					
					window.refresh
					
					case window.getch
						when 259
							current_index = (current_index-1) % processor.assets.items.size
						when 258
							current_index = (current_index+1) % processor.assets.items.size
						when 10
							options[current_index][1].call
						when 'q'
							break
					end
				end
			ensure
				window.erase
				window.refresh
				window.close
			end
		end
	end
end
