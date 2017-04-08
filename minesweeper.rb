require "curses"
require "./minesweeper_engine.rb"

# MWindow => Managed window. A layer of abstraction over a
# curses window
class MWindow
	attr_accessor :width
	attr_accessor :height
	attr_accessor :cwin # courses window

	def initialize(height, width, shared_state)
		self.cwin = Curses::Window.new(height, width, 0, 0)
		cwin.keypad(true)
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
		cwin.move(calculate_position(@anchor_y_type, @anchor_y_pos.call, height),
				  calculate_position(@anchor_x_type, @anchor_x_pos.call, width))
	end

	def calculate_position(type, pos, size)
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
	def initialize(height, width, board_height, board_width, num_mines, shared_state)
		super(height, width, shared_state)
		@board_height = board_height
		@board_width = board_width
		@pos = MinesweeperEngine::Point.new(0, 0)
		@engine = MinesweeperEngine.new(board_width, board_height, num_mines)
		@board_state = @engine.board_state
	end

	def redraw
		self.cwin.box("|", "=")
	end

	def draw
		return if !@board_state
		return if !@pos
		@board_state.each_with_index do |array_symbols, y|
			array_symbols.each_with_index do |cell_hash, x|
				cwin.setpos(y + 1, x*3 + 1)

				chr = CursesInterface.get_cell_char(cell_hash)
				color_pair_id = CursesInterface.get_cell_color(cell_hash)

				cwin.addstr (if x == @pos.x and y == @pos.y then "[" else " " end)

				cwin.attrset (Curses.color_pair(color_pair_id) | Curses::A_BOLD)
				cwin.addstr "#{chr}"
				cwin.attrset Curses.color_pair(CursesInterface::Default)

				cwin.addstr (if x == @pos.x and y == @pos.y then "]" else " " end)
			end
		end
	end

	def input
		c = cwin.getch
		case c
		when Curses::KEY_UP
			@pos.y -= 1 if @pos.y > 0
		when Curses::KEY_DOWN
			@pos.y += 1 if @pos.y < @board_height - 1
		when Curses::KEY_LEFT
			@pos.x -= 1 if @pos.x > 0
		when Curses::KEY_RIGHT
			@pos.x += 1 if @pos.x < @board_width - 1
		when "f", "F"
			@engine.flag(@pos.y, @pos.x)
			xray = !@engine.still_playing?
			@board_state = @engine.board_state(xray)
		when " ", Curses::KEY_ENTER, "\r", "\n", 10, 13
			@engine.play(@pos.y, @pos.x)
			xray = !@engine.still_playing?
			@board_state = @engine.board_state(xray)
		else
			return c
		end

		if !@engine.still_playing?
			@shared_state[:status_str] = if @engine.victory?
				"You WON!"
			else
				"You lost :( Try again!"
			end
		end

		draw
		cwin.refresh
		return nil
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

class StatusWindow < MWindow
	def redraw
	end

	def draw
		status_str = @shared_state[:status_str]
		return if !status_str
		cwin.setpos(0, 0)
		cwin.addstr(" "*self.width)
		cwin.setpos(0, (self.width - status_str.length)/2)
		cwin.addstr(status_str)
	end
end

class CursesInterface
	def self.init
		Curses.init_screen
		Curses.start_color
		Curses.nl
		Curses.noecho
		Curses.curs_set 0
		Curses.stdscr.keypad(true)
		init_colors
	end

	def initialize(width, height, num_mines)
		@width = width
		@height = height

		@shared_state = {}

		@mwindows = []

		board_window = BoardWindow.new(@height + 2, 3*@width + 2, height, width, num_mines, @shared_state)
		board_window.anchor_x(:center) {Curses.cols/2}
		board_window.anchor_y(:center) {Curses.lines/2}

		instructions_window = InstructionsWindow.new(8, 33, @shared_state)
		instructions_window.anchor_x(:left) {0}
		instructions_window.anchor_y(:top) {0}

		status_window = StatusWindow.new(1, 30, @shared_state)
		status_window.anchor_x(:center) {Curses.cols/2}
		status_window.anchor_y(:center) {
			end_of_board = (Curses.lines + @height + 2)/2 + 1
			(end_of_board + Curses.lines)/2
		}

		@mwindows << board_window
		@mwindows << instructions_window
		@mwindows << status_window

		@input_windows = @mwindows.select {|win| win.respond_to?(:input)}

		redraw
	end

	def redraw
		Curses::clear
		Curses::refresh

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

	def loop
		redraw
		draw
		@shared_state[:selected] = 0
		while true
			draw
			unhandled = @input_windows[@shared_state[:selected]].input
			case unhandled
			when Curses::KEY_RESIZE
				redraw
				draw
			when 9, "\t"
				@shared_state[:selected] =
					(@shared_state[:selected] + 1) % @input_windows.length
			when "q",  "Q"
				@mwindows.each {|mwin| mwin.cwin.close}
				exit 0
			when nil
			else
				@shared_state[:status_str] =
					("Unknown command #{Curses.keyname(unhandled)}") if unhandled != nil
			end
		end
	end

	private

	Board_format = {
		unknown: '.',
		clear: ' ',
		bomb: '#',
		flag: 'F',
		open_bomb: 'X'
	}

	Default = 1
	Blue = 2
	Cyan = 3
	Green = 4
	Magenta = 5
	Red = 6
	White = 7
	Yellow = 8

	def self.init_colors
		Curses.use_default_colors
		Curses.init_pair(Default, -1, -1)
		Curses.init_pair(Blue, Curses::COLOR_BLUE, -1)
		Curses.init_pair(Cyan, Curses::COLOR_CYAN, -1)
		Curses.init_pair(Green, Curses::COLOR_GREEN, -1)
		Curses.init_pair(Magenta, Curses::COLOR_MAGENTA, -1)
		Curses.init_pair(Red, Curses::COLOR_RED, -1)
		Curses.init_pair(White, Curses::COLOR_WHITE, -1)
		Curses.init_pair(Yellow, Curses::COLOR_YELLOW, -1)
	end

	def self.get_cell_char(cell_hash)
		if cell_hash[:type] == :clear and cell_hash[:n_surr] != 0
			cell_hash[:n_surr].to_s
		else
			Board_format[cell_hash[:type]]
		end
	end

	def self.get_cell_color(cell_hash)
		if cell_hash[:type] == :clear and cell_hash[:n_surr] != 0
			case cell_hash[:n_surr]
			when 1, 5
				return Green
			when 2, 6
				return Red
			when 3, 7
				return Blue
			when 4, 8
				return Magenta
			end
		end
		return Default
	end
end


if $0 == __FILE__
	width, height, num_mines = 10, 15, 5

	CursesInterface.init
	console = CursesInterface.new(width, height, num_mines)
	console.loop()
end