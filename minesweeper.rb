require "Set"
require "json"

class Minesweeper

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
		!@defeat and cells_list.select{|c| !c.bomb?}.all?{|c| c.open?}
	end

	def still_playing?
		!@defeat and !@victory
	end

	def flag(x, y)
		return false if !still_playing?
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
		return false if !still_playing?
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
		board.map do |line|
			line.map do |cell|
				type = nil
				n_surr = nil

				type = classify_cell(cell, xray)
				if cell.open? and !cell.bomb?
					n_surr = n_surrounding_bombs(cell.point)
				end

				{:type => type, :n_surr => n_surr}
			end
		end
	end

	def classify_cell(cell, xray)
		if xray
			if cell.bomb? and cell.flag? and cell.open?
				:invalid
			elsif cell.bomb? and cell.flag? and !cell.open?
				:bomb_flag
			elsif cell.bomb? and !cell.flag? and cell.open?
				:open_bomb
			elsif cell.bomb? and !cell.flag? and !cell.open?
				:bomb
			elsif !cell.bomb? and cell.flag? and cell.open?
				:invalid
			elsif !cell.bomb? and cell.flag? and !cell.open?
				:flag
			elsif !cell.bomb? and !cell.flag? and cell.open?
				:open_clear
			elsif !cell.bomb? and !cell.flag? and !cell.open?
				:clear
			end
		else
			if cell.bomb? and cell.flag? and cell.open?
				:invalid
			elsif cell.bomb? and cell.flag? and !cell.open?
				:flag
			elsif cell.bomb? and !cell.flag? and cell.open?
				:open_bomb
			elsif cell.bomb? and !cell.flag? and !cell.open?
				:unknown
			elsif !cell.bomb? and cell.flag? and cell.open?
				:invalid
			elsif !cell.bomb? and cell.flag? and !cell.open?
				:flag
			elsif !cell.bomb? and !cell.flag? and cell.open?
				:clear
			elsif !cell.bomb? and !cell.flag? and !cell.open?
				:unknown
			end
		end
	end

	# Returns a string containing the internal state of the game
	def save_state
		Marshal.dump(self)
	end

	def self.from_state(saved_state)
		# TODO check bounds
		
		new_engine = Marshal.load(saved_state)
		# height = board_state.length
		# width = board_state[0].length

		# new_engine = Minesweeper.new(width, height, 0)
		# board_state.each_with_index do |line, l|
		# 	line.each_with_index do |state_hash, c|
		# 		state_symbol = state_hash[:type]
		# 		cell = new_engine.board[l][c]

		# 		case state_symbol
		# 		when :bomb_flag
		# 			cell.bomb, cell.flag, cell.open = true, true, false
		# 		when :open_bomb
		# 			cell.bomb, cell.flag, cell.open = true, false, true
		# 		when :bomb
		# 			cell.bomb, cell.flag, cell.open = true, false, false
		# 		when :flag
		# 			cell.bomb, cell.flag, cell.open = false, true, false
		# 		when :open_clear
		# 			cell.bomb, cell.flag, cell.open = false, false, true
		# 		when :clear
		# 			cell.bomb, cell.flag, cell.open = false, false, false
		# 		end
		# 	end
		# end

		# # Recalculate @victory, @defeat, @n_mines
		# @n_mines = cells_list.count{|cell| cell.bomb?}
		# new_engine
	end

	attr_accessor :board

	private

	attr_accessor :width
	attr_accessor :height
	

	def populate_mines
		(0..(width*height-1)).to_a.shuffle[0...@n_mines].each { |i|
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
end

class SimplePrinter
	def print(board_state, pos = nil)
		PrettyPrinter.new.print(board_state, pos, "", false)
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

	def print(board_state, position = nil, before_line = "\t\t", border = true)
		Kernel::print "\n"
		border_width = if position
			3*board_state[0].size + 2
		else
			board_state[0].size + 2
		end

		if border then Kernel::print before_line + "_"*border_width + "\n" end
		board_state.each_with_index { |line, x|
			Kernel::print before_line
			if border then Kernel::print "|" end
			line.each_with_index { |cell, y|
				str = if cell[:type] == :clear and cell[:n_surr] != 0
					cell[:n_surr].to_s
				else
					Board_format[cell[:type]]
				end

				if position != nil and position.x == x and position.y == y
					Kernel::print "[" + str + "]"
				elsif position != nil
					Kernel::print " " + str + " "
				else
					Kernel::print str
				end
			}
			if border then Kernel::print "|" end
			Kernel::print "\n"
		}
		if border then Kernel::print before_line + "‾"*border_width + "\n" end
		Kernel::print "\n\n"
	end
end
