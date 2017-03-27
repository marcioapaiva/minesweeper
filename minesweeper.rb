class Minesweeper
	attr_accessor :width
	attr_accessor :height
	attr_accessor :board

	def initialize(width, height, n_mines)
		@width = width
		@height = height
		@n_mines = n_mines
		@board = Array.new(height) { |line| Array.new(width) { |col| Cell.new(Point.new(line, col)) } }
	end

	def print_board(xray = false)
		@board.each { |line|
			line.each { |cell|
				 if cell.flag?
					print "F"
				 elsif xray and !cell.open? and cell.bomb?
					print "B"
				 elsif !cell.open?
					print "C"
				 else
					print n_surrounding_bombs(cell.point).to_s
				 end
			}
			print "\n"
		}
		print "\n\n"
	end

	# private
	def is_valid(p)
		p.x >= 0 and p.x < @height and p.y >= 0 and p.y < @width
	end

	# private
	def neighbors(p)
		[
			Point.new(p.x-1, p.y), Point.new(p.x-1, p.y+1),
			Point.new(p.x, p.y+1), Point.new(p.x+1, p.y+1),
			Point.new(p.x+1, p.y), Point.new(p.x+1, p.y-1),
			Point.new(p.x, p.y-1), Point.new(p.x-1, p.y-1)
		].select { |p| is_valid(p) }
	end

	def n_surrounding_bombs(p)
		neighbors(p).count{|n| cell_at(n).bomb?}
	end

	def cell_at(p)
		@board[p.x][p.y]
	end
end

class Cell
	attr_accessor :flag
	alias_method :flag?, :flag

	attr_accessor :bomb
	alias_method :bomb?, :bomb

	attr_accessor :open
	alias_method :open?, :open

	attr_accessor :point

	def initialize(point)
		self.bomb = false
		self.flag = false
		self.open = false
		self.point = point
	end
end

class Point
	attr_accessor :x
	attr_accessor :y

	def initialize(x, y)
		@x = x
		@y = y
	end

	def ==(o)
		o.class == self.class && o.state == state
	end
	
	def state
		[@x, @y]
	end

	def to_s
		"(#{self.x}, #{self.y})"
	end

	alias_method :eql?, :==

	def hash
		state.hash
	end
end
