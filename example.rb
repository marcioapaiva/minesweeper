require "./minesweeper.rb"

if $0 == __FILE__
	width, height, num_mines = 6, 6, 5
	engine = Minesweeper.new(width, height, num_mines)
	printer = PrettyPrinter.new

	while engine.still_playing?
		printer.print(engine.board_state)

		flag = false
		puts "Enter move: [f] line(1-#{height}) col(1-#{width})"

		move_str = gets
		tokens = move_str.split(" ")
		if tokens[0].capitalize == "F"
			flag = true
			tokens.shift
		end
		x = tokens[0].to_i - 1
		y = tokens[1].to_i - 1

		valid = if flag
			engine.flag(x, y)
		else
			engine.play(x, y)
		end

		if !valid
			puts "Invalid move!"
		end
	end

	printer.print(engine.board_state(xray: true))

	if engine.victory?
		puts "You won!"
	else
		puts "You lost!"
	end
end