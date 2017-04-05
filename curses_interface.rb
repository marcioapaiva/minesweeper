require "curses"
require "./minesweeper_engine.rb"

class CursesInterface
	def self.init
		Curses.init_screen
		Curses.nl
		Curses.noecho
		Curses.curs_set 0
		Curses.stdscr.keypad(true)
	end

	def initialize(width, height)
		@pos = MinesweeperEngine::Point.new(0, 0)
		@width = width
		@height = height
	end

	def redraw(board_state)
		Curses.clear
		print(board_state)
	end

	def print_welcome
		Curses.setpos(0, 0)
		Curses.addstr "\nWelcome to minesweeper. Commands:\n"
		Curses.addstr " - Move: Arrows\n - Flag: F\n"
		Curses.addstr " - Click: Spacebar / Enter\n - Quit: q"
	end

	def print_bottom(str)
		end_of_board = (Curses.lines + @height + 2)/2 + 1
		Curses.setpos((end_of_board + Curses.lines)/2,
					  (Curses.cols - str.size)/2)
		Curses.addstr(str)
	end

	def print(board_state)
		print_welcome

		height = board_state.length
		width = board_state[0].length * 3
		pad_y = (Curses.lines - height - 2)/2 #padding for whole board
		pad_x = (Curses.cols - width - 2)/2 #padding for whole board

		board_state.each_with_index do |array_symbols, y|
			array_symbols.each_with_index do |cell_hash, x|
				Curses.setpos(pad_y + y + 1, pad_x + x*3 + 1)
				chr = get_cell_char(cell_hash)
				if x == @pos.x and y == @pos.y
					Curses.addstr "[#{chr}]"
				else
					Curses.addstr " #{chr} "
				end
			end
		end

		# Draw borders
		vertical_border_chr, upper_border_chr, lower_border_chr = "|", "_", "‾"

		#Upper
		Curses.setpos(pad_y, pad_x)
		Curses.addstr(upper_border_chr*(width+2))

		#Lower
		Curses.setpos(pad_y + height + 1, pad_x)
		Curses.addstr(lower_border_chr*(width+2))

		#Left and Right
		[pad_x, pad_x + width + 1].each do |x|
			(1..height).each do |dy|
				Curses.setpos(dy + pad_y, x)
				Curses.addstr(vertical_border_chr)
			end
		end

		Curses.refresh
	end

	def get_move(board_state)
		move_type = nil

		while true
			self.print(board_state)
			c = Curses.getch
			case c
			when Curses::KEY_UP
				@pos.y -= 1 if @pos.y > 0
			when Curses::KEY_DOWN
				@pos.y += 1 if @pos.y < @height - 1
			when Curses::KEY_LEFT
				@pos.x -= 1 if @pos.x > 0
			when Curses::KEY_RIGHT
				@pos.x += 1 if @pos.x < @width - 1
			when "f", "F"
				move_type = :flag
				break
			when " ", Curses::KEY_ENTER, "\r", "\n", 10, 13
				move_type = :play
				break
			when Curses::KEY_RESIZE
				redraw(board_state)
			when "q",  "Q"
				exit 0
			else
				print_bottom("Unknown command #{Curses.keyname(c)}") if c != nil
			end
		end

		return {:type => move_type, :pos => @pos}
	end

	def inform_win
		print_bottom "You won!"
	end

	def inform_defeat
		print_bottom "You lost!"
	end

	def wait_key_press
		Curses.getch
	end

	private

	Board_format = {
		unknown: '.',
		clear: ' ',
		bomb: '#',
		flag: 'F',
		open_bomb: 'X'
	}

	def get_cell_char(cell_hash)
		if cell_hash[:type] == :clear and cell_hash[:n_surr] != 0
			cell_hash[:n_surr].to_s
		else
			Board_format[cell_hash[:type]]
		end
	end
end
