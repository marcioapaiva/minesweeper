require "Set"

class Minesweeper
	attr_accessor :width
	attr_accessor :height
	attr_accessor :board

	def initialize(width, height, n_mines)
		@width = width
		@height = height
		@n_mines = n_mines
		@board = Array.new(height) { |line| Array.new(width) { |col| Cell.new(Point.new(line, col)) } }
		@defeat = false
		@victory = false
		populate_mines
	end

	def victory?
		@victory
	end

	def still_playing?
		!@defeat and !@victory
	end

	def flag(x, y)
		return false if !is_valid(Point.new(x,y))

		p = Point.new(x, y)
		if cell_at(p).open?
			false
		else
			cell_at(p).flag = !cell_at(p).flag
			true
		end
	end

	def play(x, y)
		return false if !is_valid(Point.new(x,y))

		point = Point.new(x, y)
		cell = cell_at(point)
		if cell.open? or cell.flag?
			false
		elsif cell.bomb?
			cell.open = true
			@defeat = true
			true
		else
			open_bfs(point)
			verify_victory
			true
		end
	end

	def board_state(xray = false)
		board.map{|line|
			line.map{ |cell|
				type = nil
				n_surr = nil

				if !cell.open?
					if xray and cell.bomb?
						type = :bomb
					elsif cell.flag?
						type = :flag
					else
						type = :unknown
					end
				elsif cell.bomb? #open and bomb
					type = :open_bomb
				else #open and not bomb
					n_surr = n_surrounding_bombs(cell.point)
					type = :clear
				end

				{:type => type, :n_surr => n_surr}
			}
		}
	end

	private

	def populate_mines
		(0..(width*height-1)).to_a.shuffle[0..@n_mines-1].each { |i|
			line = i/width
			col = i%width
			cell_at(Point.new(line, col)).bomb = true
		}
	end

	def open_bfs(s)
		set_queued = Set.new
		queue = []
		queue << s
		set_queued << s
		while !queue.empty?
			curr = queue.shift
			cell_at(curr).open = true
			if n_surrounding_bombs(curr) == 0
				neighbors(curr).select { |p_neighbor|
					!cell_at(p_neighbor).flag? and !cell_at(p_neighbor).open? and !set_queued.include?(p_neighbor)
				}.each { |p_neighbor|
					queue << p_neighbor
					set_queued << p_neighbor
				}
			end
		end
	end

	def cells_list
		list = []
		@board.each{ |l| l.each {|cell|
			list << cell
		}}
		list
	end

	def verify_victory
		@victory = (!@defeat and cells_list.select{|c| !c.bomb?}.all?{|c| c.open?})
	end

	def cell_at(p)
		@board[p.x][p.y]
	end

	def is_valid(p)
		p.x >= 0 and p.x < @height and p.y >= 0 and p.y < @width
	end

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
end

class SimplePrinter
	def print(board_state)
		PrettyPrinter.new.print(board_state, "")
	end
end

class PrettyPrinter
	Board_format = {
		unknown: '.',
		clear: ' ',
		bomb: '#',
		flag: 'F',
		open_bomb: 'X'
	}

	def print(board_state, before_line = "\t\t")
		Kernel::print "\n"
		board_state.each { |line|
			Kernel::print before_line
			line.each { |cell|
				str = if cell[:type] == :clear and cell[:n_surr] != 0
					cell[:n_surr].to_s
				else
					Board_format[cell[:type]]
				end

				Kernel::print str
			}
			Kernel::print "\n"
		}
		Kernel::print "\n\n"
	end
end

# class PrettyPrinter
	# def print(board_state)

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
