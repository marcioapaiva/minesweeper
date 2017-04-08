require "curses"

# MWindow => Managed window. A layer of abstraction over a
# curses window.
class MWindow
	attr_accessor :width
	attr_accessor :height
	attr_accessor :cwin # courses window

	def initialize(height, width, shared_state)
		self.cwin = Curses::Window.new(height, width, 0, 0)
		cwin.keypad(true)
		self.height = height
		self.width = width
		@shared_state = shared_state
	end

	# type is one of :center, :top, :bottom
	def anchor_y(type)
		@anchor_y_type = type
		@anchor_y_pos = Proc.new
	end

	# type is one of :center, :left, :right
	def anchor_x(type)
		@anchor_x_type = type
		@anchor_x_pos = Proc.new
	end

	def reposition
		cwin.resize(height, width)
		cwin.move(calculate_position(@anchor_y_type, @anchor_y_pos.call, height),
				  calculate_position(@anchor_x_type, @anchor_x_pos.call, width))
	end

	def calculate_position(type, pos, size)
		case type
		when :top, :left
			pos
		when :center
			pos - size/2
		when :bottom, :right
			pos - size
		end
	end
end


class MCurses
	def self.init
		Curses.init_screen
		Curses.start_color
		Curses.nl
		Curses.noecho
		Curses.curs_set 0
		Curses.stdscr.keypad(true)
		init_colors
	end

	def initialize(shared_state)
		@shared_state = shared_state

		@mwindows = []
		@input_windows = []
	end

	def add_window(mwindow)
		@mwindows << mwindow
		@input_windows = @mwindows.select {|win| win.respond_to?(:input)}

		redraw
	end

	def redraw
		Curses::clear
		Curses::refresh

		for mwindow in @mwindows
			mwindow.reposition
			mwindow.cwin.clear
			mwindow.redraw
			mwindow.cwin.refresh
		end
	end

	def draw
		for mwindow in @mwindows
			mwindow.draw
			mwindow.cwin.refresh
		end
	end

	def loop
		redraw
		draw
		@shared_state[:selected] = 0
		while true
			draw
			unhandled = @input_windows[@shared_state[:selected]].input
			case unhandled
			when Curses::KEY_RESIZE
				redraw
				draw
			when 9, "\t"
				@shared_state[:selected] =
					(@shared_state[:selected] + 1) % @input_windows.length
			when "q",  "Q"
				@mwindows.each {|mwin| mwin.cwin.close}
				exit 0
			when nil
			else
				@shared_state[:status_str] =
					("Unknown command #{Curses.keyname(unhandled)}") if unhandled != nil
			end
		end
	end

	Default = 1
	Blue = 2
	Cyan = 3
	Green = 4
	Magenta = 5
	Red = 6
	White = 7
	Yellow = 8

	private

	def self.init_colors
		Curses.use_default_colors
		Curses.init_pair(Default, -1, -1)
		Curses.init_pair(Blue, Curses::COLOR_BLUE, -1)
		Curses.init_pair(Cyan, Curses::COLOR_CYAN, -1)
		Curses.init_pair(Green, Curses::COLOR_GREEN, -1)
		Curses.init_pair(Magenta, Curses::COLOR_MAGENTA, -1)
		Curses.init_pair(Red, Curses::COLOR_RED, -1)
		Curses.init_pair(White, Curses::COLOR_WHITE, -1)
		Curses.init_pair(Yellow, Curses::COLOR_YELLOW, -1)
	end
	
end