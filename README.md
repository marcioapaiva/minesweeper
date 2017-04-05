# Minesweeper in Ruby
A simple Minesweeper console game made made with Ruby and Curses.

For ruby versions < 2.1.0
```
ruby minesweeper.rb
```

For ruby versions >= 2.1.0, curses was removed from the standard library and migrated to the "curses" gem.
```
gem install curses
ruby minesweeper.rb
```

The engine is properly isolated from the console manager. An example that does not use curses is also included:
```
ruby example_no_curses.rb
```