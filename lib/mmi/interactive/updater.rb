require 'mmi/curses/utils'
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
				Mmi::Curses::Utils.init!
				
				options = [
					['Edit modloader', -> { update_modloader }],
					['Edit assets',    -> { update_assets    }],
				]
				current_index = 0
				
				loop do
					Mmi::Curses::Utils.main_window.box('|', '-')
					
					options.each_with_index do |(text, _), index|
						Mmi::Curses::Utils.main_window.setpos(2+index, 2)
						Mmi::Curses::Utils.main_window.attron(::Curses.color_pair(current_index == index ? 1 : 0)) do
							Mmi::Curses::Utils.main_window.addstr(text)
						end
					end
					
					Mmi::Curses::Utils.main_window.refresh
					
					case Mmi::Curses::Utils.main_window.getch
						when 259
							current_index = (current_index-1) % options.size
						when 258
							current_index = (current_index+1) % options.size
						when 10
							options[current_index][1].call
						when 'q'
							if show_close_dialog
								break
							end
					end
				end
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
