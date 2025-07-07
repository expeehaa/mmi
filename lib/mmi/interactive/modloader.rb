require 'mmi/modloader/fabric'
require 'mmi/modloader/none'

module Mmi
	module Interactive
		class Modloader
			def initialize(processor)
				@processor = processor
			end
			
			def show!
				if @processor.modloader.is_a?(Mmi::Modloader::Fabric)
					update_modloader_fabric
				else
					false
				end
			end
			
			def update_modloader_fabric
				ml = @processor.modloader
				
				options = [
					[['Installer version',   ->{ ml.version                        }], -> do
						available_installer_versions = ml.available_versions.sort.reverse
						installer_version            = Mmi::Curses::Utils.prompt_choice('Choose a fabric installer version', available_installer_versions.map {|v| [v, v]}, initial_index: available_installer_versions.index(ml.version))
						ml.update_properties!({version: installer_version})
					end],
					[['Minecraft version',   ->{ ml.minecraft_version              }], -> do
						minecraft_version = Mmi::Curses::Utils.prompt_text('Minecraft version', default: ml.minecraft_version)
						ml.update_properties!({minecraft_version: minecraft_version})
					end],
					[['Download Minecraft?', ->{ ml.download_minecraft ? '✔' : '✕' }], -> do
						download_minecraft = Mmi::Curses::Utils.prompt_choice('Download Minecraft when installing?', [['Yes', true], ['No', false]], initial_index: ml.download_minecraft ? 0 : 1)
						ml.update_properties!({download_minecraft: download_minecraft})
					end],
					[['Install directory',   ->{ ml.install_dir                    }], -> do
						install_directory = Mmi::Curses::Utils.prompt_text('Modloader install directory', default: ml.install_dir)
						ml.update_properties!({install_dir: install_directory.strip.empty? || install_directory == ml.class.registered_properties[:install_dir].default ? nil : install_directory})
					end],
					[['Install type',        ->{ ml.install_type                   }], -> do
						install_type = Mmi::Curses::Utils.prompt_choice('Install type', ml.class.allowed_install_types.map {|t| [t, t]}, initial_index: ml.class.allowed_install_types.index(ml.install_type))
						ml.update_properties!({install_type: install_type})
					end],
				]
				
				keybindings = {
					10 => -> { options[it][1].call },
				}
				
				Mmi::Curses::Utils.show_table_window!(options.map(&:first), keybindings)
			end
		end
	end
end
