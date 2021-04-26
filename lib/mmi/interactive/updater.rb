require 'mmi/interactive/modloader'
require 'mmi/interactive/assets'

module Mmi
	module Interactive
		class Updater
			include Modloader
			include Assets
			
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
		end
	end
end
