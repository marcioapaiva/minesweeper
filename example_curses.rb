require "io/console"
require "./curses_interface.rb"
require "./minesweeper.rb"

if $0 == __FILE__
	width, height, num_mines = 6, 6, 5
	engine = Minesweeper.new(width, height, num_mines)
	console = CursesInterface.new(width, height)
	CursesInterface.init

	while engine.still_playing?
		move = console.get_move(engine.board_state)

		case move[:type]
		when :flag
			engine.flag(move[:pos].y, move[:pos].x)
		when :play
			engine.play(move[:pos].y, move[:pos].x)
		end
	end

	console.print(engine.board_state(xray: true))

	if engine.victory?
		console.inform_win
	else
		console.inform_defeat
	end

	console.wait_key_press
end