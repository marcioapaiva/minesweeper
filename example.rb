require "./minesweeper.rb"

if $0 == __FILE__
	width, height, num_mines = 6, 6, 8
	engine = Minesweeper.new(width, height, num_mines)
	printer = SimplePrinter.new

	while engine.still_playing?
		printer.print(engine.board_state)

		flag = false
		puts "Enter move: ([f] x y)"

		move_str = gets
		tokens = move_str.split(" ")
		if tokens[0].capitalize == "F"
			flag = true
			tokens.shift
		end
		x = tokens[0].to_i
		y = tokens[1].to_i

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


=begin

Intended usage example

width, height, num_mines = 10, 20, 50
game = Minesweeper.new(width, height, num_mines)

while game.still_playing?
  valid_move = game.play(rand(width), rand(height))
  valid_flag = game.flag(rand(width), rand(height))
  if valid_move or valid_flag
  printer = (rand > 0.5) ? SimplePrinter.new : PrettyPrinter.new
  printer.print(game.board_state)
  end
end

puts "Fim do jogo!"
if game.victory?
  puts "Você venceu!"
else
  puts "Você perdeu! As minas eram:"
  PrettyPrinter.new.print(game.board_state(xray: true))
end
	
=end