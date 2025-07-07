require 'mmi/curses/utils'
require 'mmi/interactive/modloader'
require 'mmi/interactive/assets'

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
				Mmi::Curses::Utils.init!
				
				options = [
					[['Edit modloader'], -> { Modloader.new(self.processor).show! }],
					[['Edit assets'   ], -> { Assets   .new(self.processor).show! }],
				]
				
				keybindings = {
					10  => ['Choose selection.',       ->    { options[it][1].call              }],
					'q' => ['Quit (asks for saving).', ->(_) { show_close_dialog ? :break : nil }],
				}
				
				Mmi::Curses::Utils.show_table_window!(options.map(&:first), keybindings, Mmi::Curses::Utils.main_window)
			ensure
				::Curses.close_screen
			end
			
			def show_close_dialog
				options = [
					['Yes',   -> do
						yaml = self.processor.to_h.to_yaml
						File.write(File.expand_path(self.file_path, Dir.pwd), yaml)
						true
					end],
					['No',    -> { true  }],
					['Abort', -> { false }],
				]
				
				Mmi::Curses::Utils.prompt_choice('Save to file before quitting?', options).call
			end
		end
	end
end
