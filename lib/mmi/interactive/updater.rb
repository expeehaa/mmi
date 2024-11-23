require 'curses'

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
			
			def main_window
				@main_window ||= Curses::Window.new(0, 0, 0, 0).tap do |window|
					window.keypad true
				end
			end
			
			def run!
				Curses.init_screen
				Curses.start_color
				Curses.curs_set(0)
				Curses.noecho
				
				Curses.init_pair(1, 1, 0)
				Curses.init_pair(2, 0, 7)
				
				options = [
					['Edit modloader', -> { update_modloader }],
					['Edit assets',    -> { update_assets    }],
				]
				current_index = 0
				
				loop do
					main_window.box('|', '-')
					
					options.each_with_index do |(text, _), index|
						main_window.setpos(2+index, 2)
						main_window.attron(Curses.color_pair(current_index == index ? 1 : 0)) do
							main_window.addstr(text)
						end
					end
					
					main_window.refresh
					
					case main_window.getch
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
				Curses.close_screen
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
				
				prompt_choice('Save to file before quitting?', options).call
			end
			
			def prompt_choice(prompt, options, max_rows: 10, initial_index: 0)
				height = 2 + 1 + 1 + [options.size, max_rows].min # 2 border rows, 1 prompt row, 1 empty row, 1 row for each option
				width  = 2 + 2 + [options.map{|o| o[0].length}.max, prompt.length].max # 2 border columns, 2 empty columns adjacent to borders, as many additional as needed to display the text
				
				window = main_window.subwin(height, width, (main_window.maxy-height)/2, (main_window.maxx-width)/2)
				window.keypad true
				
				current_index = initial_index
				
				loop do
					window.box('|', '-')
					window.setpos(1, 2)
					window.addstr(prompt)
					
					pos_start = current_index - (max_rows/2.0).floor
					pos_end   = current_index + (max_rows/2.0).ceil
					
					if pos_start < 0
						pos_start  = 0
						pos_end    = max_rows
					elsif pos_end > options.size
						pos_start = options.size - max_rows
						pos_end   = options.size
					end
					
					options[pos_start...pos_end].each_with_index do |(text, _), index|
						window.setpos(3 + index, 2)
						window.attron(Curses.color_pair(current_index == pos_start+index ? 1 : 0)) do
							window.addstr(text)
						end
						
						additional_whitespace = width - 4 - text.length
						if additional_whitespace > 0
							window.addstr(' ' * additional_whitespace)
						end
					end
					
					window.refresh
					
					case window.getch
						when 259 # up arrow key
							current_index = (current_index-1) % options.size
						when 258 # down arrow key
							current_index = (current_index+1) % options.size
						when 10 # enter
							break
					end
				end
				
				options[current_index][1]
			ensure
				window.erase
				window.refresh
				window.close
			end
			
			def prompt_text(prompt, default: '', allowed_characters: %r{[\d\w\.-/]})
				height = 5
				width  = prompt.length + 4
				window = main_window.subwin(height, width, (main_window.maxy-height)/2, (main_window.maxx-width)/2)
				window.keypad true
				
				typed_text              = default.dup || ''
				cursor_position_in_text = typed_text.length > 0 ? typed_text.length : 0
				text_display_length     = width - 4 - 1 # 2 border, 2 empty adjacent to border, 1 cursor
				
				Curses.curs_set(1)
				
				loop do
					window.box('|', '-')
					window.setpos(1, 2)
					window.addstr(prompt)
					
					window.setpos(3, 2)
					window.attron(Curses.color_pair(2)) do
						if typed_text.length <= text_display_length
							window.addstr(typed_text)
							
							additional_whitespace = text_display_length - typed_text.length
							if additional_whitespace > 0
								window.addstr(' ' * additional_whitespace)
							end
							
							window.setpos(3, 2+cursor_position_in_text)
						else
							pos_start = cursor_position_in_text - (text_display_length/2.0).floor
							pos_end   = cursor_position_in_text + (text_display_length/2.0).ceil
							
							if pos_start < 0
								pos_start = 0
								pos_end   = text_display_length
							elsif pos_end > typed_text.length
								pos_start = typed_text.length - text_display_length
								pos_end   = typed_text.length
							end
							
							window.addstr(typed_text[pos_start...pos_end])
							window.setpos(3, 2+(cursor_position_in_text-pos_start))
						end
					end
					
					window.refresh
					
					case (ch = window.getch)
						when /\A#{allowed_characters}\z/
							typed_text.insert(cursor_position_in_text, ch)
							cursor_position_in_text += 1
						when 10
							break
						when 260 # left arrow key
							if cursor_position_in_text > 0
								cursor_position_in_text -= 1
							end
						when 261 # right arrow key
							if cursor_position_in_text < typed_text.length
								cursor_position_in_text += 1
							end
						when 1 # ctrl+a
							cursor_position_in_text = 0
						when 360 # end key
							cursor_position_in_text = typed_text.length
						when 263 # backspace key
							if cursor_position_in_text > 0
								cursor_position_in_text -= 1
								typed_text.slice!(cursor_position_in_text)
							end
						when 330 # delete key
							if cursor_position_in_text < typed_text.length
								typed_text.slice!(cursor_position_in_text)
							end
					end
				end
				
				typed_text
			ensure
				window.erase
				window.refresh
				window.close
				Curses.curs_set(0)
			end
		end
	end
end
