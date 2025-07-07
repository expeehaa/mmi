require 'curses'

module Mmi
	module Curses
		module Utils
			def self.main_window
				@main_window ||= ::Curses::Window.new(0, 0, 0, 0).tap do |window|
					window.keypad true
				end
			end
			
			def self.init!
				::Curses.init_screen
				::Curses.start_color
				::Curses.curs_set(0)
				::Curses.noecho
				
				::Curses.init_pair(1, 1, 0)
				::Curses.init_pair(2, 0, 7)
			end
			
			def self.destroy_window!(window)
				window.erase
				window.refresh
				window.close
				::Curses.curs_set(0)
			end
			
			def self.show_keybindings!(keybindings)
				unless keybindings.is_a?(Hash) && keybindings.values.all? { it.is_a?(Array) && it.size == 2 && it[0].is_a?(String) }
					raise "Invalid keybindings: #{keybindings}"
				end
				
				name_map = {
					  1 => 'Ctrl + a',
					 10 => 'Enter',
					258 => 'Arrow down',
					259 => 'Arrow up',
					260 => 'Arrow left',
					261 => 'Arrow right',
					263 => 'Backspace',
					330 => 'Delete',
					360 => 'End',
				}
				
				lines = keybindings.map do |k, (description, _)|
					[name_map.fetch(k, k), description]
				end.then do |arrays|
					column_widths = arrays.transpose.map do |column|
						column.map(&:length).max
					end
					
					arrays.map do |line|
						line.map.with_index do |entry, index|
							entry.ljust(column_widths[index])
						end.join(' - ')
					end
				end
				
				height = 2 + lines.size # 2 border rows, 1 for each keybinding
				width  = 2 + 2 + lines.map(&:length).max # 2 border column, 2 empty columns adjacent to borders, maximum line length
				
				window = self.main_window.subwin(height, width, (self.main_window.maxy-height)/2, (self.main_window.maxx-width)/2)
				window.keypad true
				
				window.box('|', '-')
				lines.each.with_index do |line, index|
					window.setpos(1+index, 2)
					window.addstr(line)
				end
				
				window.refresh
				
				window.getch
			ensure
				self.destroy_window!(window)
			end
			
			def self.prompt_choice(prompt, options, max_rows: 10, initial_index: 0)
				height = 2 + 1 + 1 + [options.size, max_rows].min # 2 border rows, 1 prompt row, 1 empty row, 1 row for each option
				width  = 2 + 2 + [options.map{|o| o[0].length}.max, prompt.length].max # 2 border columns, 2 empty columns adjacent to borders, as many additional as needed to display the text
				
				window = self.main_window.subwin(height, width, (self.main_window.maxy-height)/2, (self.main_window.maxx-width)/2)
				window.keypad true
				
				current_index = initial_index
				
				keybindings = {
					259 => ['Select the item above.',     ->(_) { current_index = (current_index-1) % options.size }], # up arrow key
					258 => ['Select the item below.',     ->(_) { current_index = (current_index+1) % options.size }], # down arrow key
					 10 => ['Choose selection.',          ->(_) { :break                                           }], # enter key
					'?' => ['Show this keybinding help.', ->(_) { self.show_keybindings!(keybindings)              }],
				}
				
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
						window.attron(::Curses.color_pair(current_index == pos_start+index ? 1 : 0)) do
							window.addstr(text)
						end
						
						additional_whitespace = width - 4 - text.length
						if additional_whitespace > 0
							window.addstr(' ' * additional_whitespace)
						end
					end
					
					window.refresh
					
					case (task = keybindings.fetch(window.getch, :not_found))
						when Array
							if task[1].call(current_index) == :break
								break
							end
						when :not_found
							# No binding exists, ignore the input.
						else
							raise "Unexpected task: #{task.inspect}"
					end
				end
				
				options[current_index][1]
			ensure
				destroy_window!(window)
			end
			
			def self.prompt_text(prompt, default: '', allowed_characters: %r{[\d\w\.\-_/]})
				height = 5
				width  = prompt.length + 4
				window = self.main_window.subwin(height, width, (self.main_window.maxy-height)/2, (self.main_window.maxx-width)/2)
				window.keypad true
				
				typed_text              = default.dup || ''
				cursor_position_in_text = typed_text.length > 0 ? typed_text.length : 0
				text_display_length     = width - 4 - 1 # 2 border, 2 empty adjacent to border, 1 cursor
				
				::Curses.curs_set(1)
				
				keybindings = {
					 10 => ['Be done.',                            -> { :break                                                                                                                       }],
					260 => ['Move cursor to the left.',            -> { cursor_position_in_text = [0,                 cursor_position_in_text-1].max                                                 }], # left arrow key
					261 => ['Move cursor to the right.',           -> { cursor_position_in_text = [typed_text.length, cursor_position_in_text+1].min                                                 }], # right arrow key
					  1 => ['Move cursor to the beginning.',       -> { cursor_position_in_text = 0                                                                                                  }], # ctrl+a
					360 => ['Move cursor to the end.',             -> { cursor_position_in_text = typed_text.length                                                                                  }], # end key
					263 => ['Delete character before the cursor.', -> { cursor_position_in_text = [0,                 cursor_position_in_text-1].max; typed_text.slice!(cursor_position_in_text)     }], # backspace key
					330 => ['Delete character on the cursor.',     -> { if cursor_position_in_text < typed_text.length then                           typed_text.slice!(cursor_position_in_text) end }], # delete key
					'?' => ['Show this keybinding help.',          -> { self.show_keybindings!(keybindings)                                                                                          }],
				}
				
				loop do
					window.box('|', '-')
					window.setpos(1, 2)
					window.addstr(prompt)
					
					window.setpos(3, 2)
					window.attron(::Curses.color_pair(2)) do
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
					
					ch = window.getch
					
					if ch.is_a?(String) && /\A#{allowed_characters}\z/.match?(ch)
						typed_text.insert(cursor_position_in_text, ch)
						cursor_position_in_text += 1
					else
						case (task = keybindings.fetch(ch, :not_found))
							when Array
								if task[1].call == :break
									break
								end
							when :not_found
								# No binding exists, ignore the input.
							else
								raise "Unexpected task: #{task.inspect}"
						end
					end
				end
				
				typed_text
			ensure
				destroy_window!(window)
			end
			
			def self.show_table_window!(rows, keybindings = {}, window = nil)
				window ||= self.main_window.subwin(0, 0, 0, 0)
				window.keypad true
				
				if !rows.is_a?(Proc) && (!rows.is_a?(Array) || rows.any?{ !it.is_a?(Array) })
					raise "rows must be a valid Array or a Proc, but was #{rows.inspect}"
				end
				
				unless keybindings.values.all? do |value|
					value.is_a?(Array) && value.size == 2 && value[0].is_a?(String) && value[1].is_a?(Proc) && value[1].arity == 1
				end
					raise "Invalid keybindings: #{keybindings.inspect}"
				end
				
				current_index = 0
				row_count     = rows.is_a?(Array) ? rows.size : 0
				
				keybindings = {
					259 => ['Select the item above.',     ->(i) { current_index = (i-1) % row_count   }],
					258 => ['Select the item below.',     ->(i) { current_index = (i+1) % row_count   }],
					'q' => ['Quit.',                      ->(_) { :break                              }],
					'?' => ['Show this keybinding help.', ->(_) { self.show_keybindings!(keybindings) }],
				}.merge(keybindings)
				
				loop do
					window.box('|', '-')
					
					if rows.is_a?(Proc)
						rows.call.then do |generated_rows|
							if !generated_rows.is_a?(Array) || generated_rows.any?{ !it.is_a?(Array) }
								raise "Invalid table rows: #{generated_rows.inspect}"
							end
							
							new_row_count = generated_rows.size
							
							if new_row_count < row_count
								(row_count-new_row_count).times do
									generated_rows.push([''])
								end
								
								current_index = [(current_index - row_count + new_row_count), 0].max % new_row_count
							end
							
							row_count = new_row_count
							generated_rows
						end
					else
						rows
					end.map do |row|
						row.map do |cell|
							if cell.is_a?(Proc) && cell.arity == 0
								cell.call
							else
								cell.to_s
							end
						end
					end.then do |evaluated_rows|
						max_columns = evaluated_rows.map(&:size).max
						
						evaluated_rows.map do |row|
							row + ['']*(max_columns - row.size)
						end
					end.tap do |same_size_evaluated_rows|
						column_lengths = same_size_evaluated_rows.transpose.map do |column|
							column.map(&:length).max
						end
						
						same_size_evaluated_rows.each.with_index do |row, row_index|
							window.attron(::Curses.color_pair(current_index == row_index ? 1 : 0)) do
								window.setpos(2+row_index, 2)
								
								row.map.with_index do |cell, cell_index|
									cell.ljust(column_lengths[cell_index])
								end.join('  ').ljust(window.maxx-4).tap do |str|
									window.addstr(str)
								end
							end
						end
					end
					
					window.refresh
					
					case (task = keybindings.fetch(window.getch, :not_found))
						when Array
							if task[1].call(current_index) == :break
								break
							end
						when :not_found
							# No binding exists, ignore the input.
						else
							raise "Unexpected task: #{task.inspect}"
					end
				end
			ensure
				self.destroy_window!(window)
			end
		end
	end
end
