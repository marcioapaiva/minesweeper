class Minesweeper
	def initialize(width, height, n_mines)
		@width = width
		@height = height
		@n_mines = n_mines
	end

	def print_params()
		puts "width = " + @width.to_s
		puts "height = " + @height.to_s
		puts "number of bombs = " + @n_mines.to_s
	end
end

engine = Minesweeper.new(10, 10, 9) # 10x10 and 9 bombs
engine.print_params

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