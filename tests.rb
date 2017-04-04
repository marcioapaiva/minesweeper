require "./minesweeper.rb"
require "test/unit"


class TestCell < Test::Unit::TestCase
	def test_load_state_noflags
		engine = Minesweeper.new(10, 10, 20)
		new_engine = Minesweeper.from_state(engine.save_state)
		assert_equal new_engine.board_state(true), engine.board_state(true)
	end

	def test_load_state_flagged_bomb
		engine = Minesweeper.new(2, 1, 1)
		assert engine.flag(0, 0)
		assert engine.flag(0, 1)
		new_engine = Minesweeper.from_state(engine.save_state)
		assert_equal engine.board_state(true), new_engine.board_state(true)
	end

	def test_load_state_open_clear
		engine = Minesweeper.new(1, 1, 0)
		assert engine.play(0, 0)
		new_engine = Minesweeper.from_state(engine.save_state)
		assert_equal engine.board_state(true), new_engine.board_state(true)
	end

	def test_load_state_open_bomb
		engine = Minesweeper.new(1, 1, 1)
		assert engine.play(0, 0)
		new_engine = Minesweeper.from_state(engine.save_state)
		assert_equal engine.board_state(true), new_engine.board_state(true)
		assert !new_engine.play(0, 0)
	end

	def test_unknown_state
		engine = Minesweeper.new(1, 1, 1)
		assert_equal engine.board_state[0][0][:type], :unknown
	end

	def test_clear_state
		engine = Minesweeper.new(1, 1, 0)
		assert_equal engine.board_state(true)[0][0][:type], :clear
		assert_equal engine.board_state()[0][0][:type], :unknown
	end

	def test_bomb_state
		engine = Minesweeper.new(1, 1, 1)
		assert_equal engine.board_state(true)[0][0][:type], :bomb
	end

	def test_open_bomb_state
		engine = Minesweeper.new(1, 1, 1)
		engine.play(0, 0)
		assert_equal engine.board_state(true)[0][0][:type], :open_bomb
	end

	def test_bomb_flag_state
		engine = Minesweeper.new(1, 1, 1)
		engine.flag(0, 0)
		assert_equal engine.board_state[0][0][:type], :flag
	end

	def test_bomb_flag_xray_state
		engine = Minesweeper.new(1, 1, 1)
		engine.flag(0, 0)
		assert_equal engine.board_state(true)[0][0][:type], :bomb_flag
	end

	# def test_populate_mines
	# 	engine = Minesweeper.new(1, 1, 0)
	# 	assert_equal engine.board_state(true)[0][0][:type], 
	# end

	# def test_load_state_consistent
	# 	engine = Minesweeper.new(10, 10, 10)
	# 	engine.flag (5, 5)
	# 	assert_equal engine.
	# end


	# def test_play_on_bomb
	# 	engine = Minesweeper.new(5, 5, 0)
	# 	engine.flag(2, 2)
	# 	assert_equal(false, engine.play(2,2))
	# 	assert_equal(true, engine.play(1,1))
	# 	engine.flag(2, 2) #unflag
	# end
end