require "io/console"
require "./console_interface.rb"
require "./minesweeper.rb"

if $0 == __FILE__
	width, height, num_mines = 6, 6, 5
	engine = Minesweeper.new(width, height, num_mines)
	console = ConsoleInterface.new(width, height)

	print "\nWelcome to minesweeper. Commands:\n"
	print " - Move: Arrows\n - Flag: F\n"
	print " - Click: Spacebar / Enter\n - Quit: q / ^C"

	while engine.still_playing?
		move = console.get_move(engine.board_state)

		case move[:type]
		when :flag
			engine.flag(move[:pos].x, move[:pos].y)
		when :play
			engine.play(move[:pos].x, move[:pos].y)
		end
	end

	console.print(engine.board_state(xray: true))

	if engine.victory?
		puts "You won!"
	else
		puts "You lost!"
	end
end