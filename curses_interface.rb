require "curses"
require "./minesweeper_engine.rb"

# MWindow => Managed window. A layer of abstraction over a
# curses window
class MWindow
	attr_accessor :width
	attr_accessor :height
	attr_accessor :cwin # courses window

	def initialize(height, width)
		self.cwin = Curses::Window.new(width, height, 0, 0)
		self.height = height
		self.width = width
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

	def redraw(bs)
	end

	def draw(bs)
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
	def initialize(height, width, interface)
		@interface = interface
		super(height, width)
	end

	def redraw(bs)
		self.cwin.box("|", "=")
		self.draw(bs)
	end

	def draw(bs)
		if bs == nil
			return
		end
		bs.each_with_index do |array_symbols, y|
			array_symbols.each_with_index do |cell_hash, x|
				cwin.setpos(y + 1, x*3 + 1)
				chr = CursesInterface.get_cell_char(cell_hash)
				if x == @interface.pos.x and y == @interface.pos.y
					cwin.addstr "[#{chr}]"
				else
					cwin.addstr " #{chr} "
				end
			end
		end
	end
end

class CursesInterface
	attr_accessor :pos

	def self.init
		Curses.init_screen
		Curses.nl
		Curses.noecho
		Curses.curs_set 0
		Curses.stdscr.keypad(true)
	end

	def initialize(width, height)
		self.pos = MinesweeperEngine::Point.new(0, 0)
		@width = width
		@height = height

		@mwindows = []
		@bwin = BoardWindow.new(@height + 2, 3*@width + 2, self)
		@bwin.anchor_x(:center) {Curses.cols/2}
		@bwin.anchor_y(:center) {Curses.lines/2}
		@mwindows << @bwin

		redraw(nil)
	end

	def redraw(bs)
		Curses.clear
		print_welcome
		Curses.refresh

		@bwin.reposition

		for mwindow in @mwindows
			mwindow.cwin.clear
			mwindow.redraw(bs)
			mwindow.draw(bs)
			mwindow.cwin.refresh
		end
	end

	def draw(bs)
		for mwindow in @mwindows
			mwindow.draw(bs)
			mwindow.cwin.refresh
		end
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
		

		# Curses.refresh
		@bwin.cwin.refresh
	end

	def get_move(board_state)
		move_type = nil

		while true
			# self.print(board_state)
			self.draw(board_state)
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
				redraw(board_state)
			when "q",  "Q"
				@bwin.cwin.close
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
