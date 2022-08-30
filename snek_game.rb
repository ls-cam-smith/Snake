require 'gosu'

require './banner'
require './config'
require './dummy'
require './fruit'
require './game_over'
require './scoreboard'
require './snek_player.rb'
require './sounds'

class SnekGame < Gosu::Window
  def initialize
    super(Config::WINDOW_X, Config::WINDOW_Y)
    @game_in_progress = false
    @paused = false
    @player = DummyElement.new
    @scoreboard = Scoreboard.new
    @overlay_ui = Banner.new('Press space to start')
    @fruit_manager = DummyElement.new
    @sound_manager = SoundManager.new
    @input_buffer = Queue.new
  end

  def start_game
    @game_in_progress = true
    @player = SnekPlayer.new
    @fruit_manager = FruitManager.new
    @overlay_ui = DummyElement.new
    @scoreboard.reset
    return
  end

  def game_over
    @game_in_progress = false
    @overlay_ui = Banner.new('Game Over', 'Press space to restart')
    @scoreboard.save
  end

  def update
    if @game_in_progress and not @paused
      6.times { |x| sleep 0.01 }
      @player.handle_keypress @input_buffer.pop if not @input_buffer.empty?

      begin
        head_position = @player.movement_tick
      rescue
        game_over
        @sound_manager.death_knell
      end

      if head_position == @fruit_manager.fruit_coordinates
        context = {
          :points => 1,
          :occupied_coordinates => @player.occupied_coordinates
        }
        EventHandler.publish_event(:fruit_eaten, context)
      end

    end
  end

  def draw
    @player.draw
    @fruit_manager.draw
    @scoreboard.draw
    @overlay_ui.draw
  end

  def button_down(id)
    if not @game_in_progress and id == Gosu::KB_SPACE
      start_game
      return
    elsif not @game_in_progress
      return
    elsif not @paused and @player.key_bindings.include? id
      @input_buffer << id
    elsif @game_in_progress and id == Gosu::KB_P
      @paused = (not @paused)
      @sound_manager.pause_toggled(@paused)
    end
  end
end

SnekGame.new.show