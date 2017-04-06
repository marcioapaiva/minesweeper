require "io/console"
require "./curses_interface.rb"
require "./minesweeper_engine.rb"

if $0 == __FILE__
	width, height, num_mines = 10, 10, 5
	engine = MinesweeperEngine.new(width, height, num_mines)
	CursesInterface.init
	console = CursesInterface.new(width, height)

	while engine.still_playing?
		console.board_state = engine.board_state
		move = console.get_move

		case move[:type]
		when :flag
			engine.flag(move[:pos].y, move[:pos].x)
		when :play
			engine.play(move[:pos].y, move[:pos].x)
		end
	end

	console.board_state = engine.board_state(xray: true)

	if engine.victory?
		console.inform_win
	else
		console.inform_defeat
	end

	console.wait_key_press
end