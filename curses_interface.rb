require "curses"
require "./minesweeper_engine.rb"

# MWindow => Managed window. A layer of abstraction over a
# curses window
class MWindow
	attr_accessor :width
	attr_accessor :height
	attr_accessor :cwin # courses window

	def initialize(height, width, shared_state)
		self.cwin = Curses::Window.new(width, height, 0, 0)
		self.height = height
		self.width = width
		@shared_state = shared_state
	end

	# type is one of :center, :top, :bottom
	def anchor_y(type)
		@anchor_y_type = type
		@anchor_y_pos = Proc.new
	end

	# type is one of :center, :left, :right
	def anchor_x(type)
		@anchor_x_type = type
		@anchor_x_pos = Proc.new
	end

	def reposition
		cwin.resize(height, width)
		cwin.move(calc_pos(@anchor_y_type, @anchor_y_pos.call, height),
				  calc_pos(@anchor_x_type, @anchor_x_pos.call, width))
	end

	def calc_pos(type, pos, size)
		case type
		when :top, :left
			pos
		when :center
			pos - size/2
		when :bottom, :right
			pos - size
		end
	end
end

class BoardWindow < MWindow
	def redraw
		self.cwin.box("|", "=")
	end

	def draw
		board_state = @shared_state[:board_state]
		pos = @shared_state[:pos]
		return if !board_state
		return if !pos
		board_state.each_with_index do |array_symbols, y|
			array_symbols.each_with_index do |cell_hash, x|
				cwin.setpos(y + 1, x*3 + 1)
				chr = CursesInterface.get_cell_char(cell_hash)
				if x == pos.x and y == pos.y
					cwin.addstr "[#{chr}]"
				else
					cwin.addstr " #{chr} "
				end
			end
		end
	end
end

class InstructionsWindow < MWindow
	def redraw
		cwin.setpos(0, 0)
		cwin.addstr "\nWelcome to minesweeper. Commands:\n"
		cwin.addstr " - Move: Arrows\n - Flag: F\n"
		cwin.addstr " - Click: Spacebar / Enter\n - Quit: q"
	end

	def draw
	end
end

class CursesInterface
	def self.init
		Curses.init_screen
		Curses.nl
		Curses.noecho
		Curses.curs_set 0
		Curses.stdscr.keypad(true)
	end

	def initialize(width, height)
		@width = width
		@height = height

		@shared_state = {}
		@shared_state[:pos] = MinesweeperEngine::Point.new(0, 0)

		@mwindows = []

		board_window = BoardWindow.new(@height + 2, 3*@width + 2, @shared_state)
		board_window.anchor_x(:center) {Curses.cols/2}
		board_window.anchor_y(:center) {Curses.lines/2}

		instructions_window = InstructionsWindow.new(8, 40, @shared_state)
		instructions_window.anchor_x(:left) {0}
		instructions_window.anchor_y(:top) {0}

		@mwindows << instructions_window
		@mwindows << board_window

		redraw
	end

	def board_state=(board_state)
		@shared_state[:board_state] = board_state
	end

	def redraw
		Curses.clear
		Curses.refresh

		for mwindow in @mwindows
			mwindow.reposition
			mwindow.cwin.clear
			mwindow.redraw
			mwindow.cwin.refresh
		end
	end

	def draw
		for mwindow in @mwindows
			mwindow.draw
			mwindow.cwin.refresh
		end
	end

	def print_bottom(str)
		end_of_board = (Curses.lines + @height + 2)/2 + 1
		Curses.setpos((end_of_board + Curses.lines)/2,
					  (Curses.cols - str.size)/2)
		Curses.addstr(str)
	end

	def get_move
		move_type = nil

		while true
			draw
			pos = @shared_state[:pos]
			c = Curses.getch
			case c
			when Curses::KEY_UP
				pos.y -= 1 if pos.y > 0
			when Curses::KEY_DOWN
				pos.y += 1 if pos.y < @height - 1
			when Curses::KEY_LEFT
				pos.x -= 1 if pos.x > 0
			when Curses::KEY_RIGHT
				pos.x += 1 if pos.x < @width - 1
			when "f", "F"
				move_type = :flag
				break
			when " ", Curses::KEY_ENTER, "\r", "\n", 10, 13
				move_type = :play
				break
			when Curses::KEY_RESIZE
				redraw
				draw
			when "q",  "Q"
				@mwindows.each{ |win| win.cwin.close }
				exit 0
			else
				print_bottom("Unknown command #{Curses.keyname(c)}") if c != nil
			end
		end

		return {:type => move_type, :pos => pos}
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

	def self.get_cell_char(cell_hash)
		if cell_hash[:type] == :clear and cell_hash[:n_surr] != 0
			cell_hash[:n_surr].to_s
		else
			Board_format[cell_hash[:type]]
		end
	end
end
