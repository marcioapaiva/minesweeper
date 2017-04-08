require "curses"
require "./mcurses.rb"
require "./minesweeper_engine.rb"

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

				chr = MCursesInterface.get_cell_char(cell_hash)
				color_pair_id = MCursesInterface.get_cell_color(cell_hash)

				cwin.addstr (if x == @pos.x and y == @pos.y then "[" else " " end)

				cwin.attrset (Curses.color_pair(color_pair_id) | Curses::A_BOLD)
				cwin.addstr "#{chr}"
				cwin.attrset Curses.color_pair(MCurses::Default)

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

class MCursesInterface
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
				return MCurses::Green
			when 2, 6
				return MCurses::Red
			when 3, 7
				return MCurses::Blue
			when 4, 8
				return MCurses::Magenta
			end
		end
		return MCurses::Default
	end

	private
	Board_format = {
		unknown: '.',
		clear: ' ',
		bomb: '#',
		flag: 'F',
		open_bomb: 'X'
}
end

if $0 == __FILE__
	width, height, num_mines = 10, 15, 5
	shared_state = {}
	
	MCurses.init
	mcurses = MCurses.new(shared_state)

	board_window = BoardWindow.new(height + 2, 3*width + 2, height, width, num_mines, shared_state)
	board_window.anchor_x(:center) {Curses.cols/2}
	board_window.anchor_y(:center) {Curses.lines/2}

	instructions_window = InstructionsWindow.new(8, 33, shared_state)
	instructions_window.anchor_x(:left) {0}
	instructions_window.anchor_y(:top) {0}

	status_window = StatusWindow.new(1, 30, shared_state)
	status_window.anchor_x(:center) {Curses.cols/2}
	status_window.anchor_y(:center) {
		end_of_board = (Curses.lines + height + 2)/2 + 1
		(end_of_board + Curses.lines)/2
	}

	mcurses.add_window(board_window)
	mcurses.add_window(instructions_window)
	mcurses.add_window(status_window)

	mcurses.loop()
end