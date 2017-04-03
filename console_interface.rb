require "./minesweeper.rb"

class ConsoleInterface

	def initialize(width, height)
		@printer = PrettyPrinter.new
		@pos = Minesweeper::Point.new(0, 0)
	end

	def print(board_state)
		@printer.print(board_state, @pos)
	end

	def get_move(board_state)
		flag = false

		c = ""
		while c.capitalize != "F" and c != " "
			@printer.print(board_state, @pos)
			c = read_char
			case c
			when UP_ARR
				@pos.x -= 1
			when DOWN_ARR
				@pos.x += 1
			when LEFT_ARR
				@pos.y -= 1
			when RIGHT_ARR
				@pos.y += 1
			when "\u0003", "q"
				exit 0
			end
		end

		flag = c.capitalize == "F"

		if flag
			return {:type => :flag, :pos => @pos}
		else
			return {:type => :play, :pos => @pos}
		end
	end

	private
	# Reads keypresses including 2 and 3 char escape sequences
	def read_char
	  STDIN.echo = false
	  STDIN.raw!

	  input = STDIN.getc.chr
	  if input == "\e" then
	    input << STDIN.read_nonblock(3) rescue nil
	    input << STDIN.read_nonblock(2) rescue nil
	  end
	ensure
	  STDIN.echo = true
	  STDIN.cooked!

	  return input
	end

	UP_ARR = "\e[A"
	DOWN_ARR = "\e[B"
	RIGHT_ARR = "\e[C"
	LEFT_ARR = "\e[D"
end
