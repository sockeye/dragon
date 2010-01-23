# encoding: utf-8
class Player
  attr_reader :name
  attr_accessor :state, :data, :score
  
  def initialize(user, state)
    @name = user.name
    @state = state
    @data = {}
    @score = 0
  end
  
  def output(message)
    u = Talker.instance.connected_users[@name.downcase]
    u.output(message) if u
  end
end

class Game
  include TalkerUtilities
  @@games = []
  
  attr_reader :players
  
  def initialize
    @@games << self
    @players = []
    @turn = nil
  end
    
  def self.find(user, type)
    games = @@games.select {|g| g.class.name == type && g.includes_player?(user)}
    games.empty? ? nil : games.first
  end
    
  def self.games
    @@games
  end
  
  def includes_player?(user)
    @players.select {|p| user.lower_name == p.name.downcase}.length == 1
  end
  
  def player(user)
    result = @players.select {|p| user.lower_name == p.name.downcase}
    result.empty? ? nil : result.first
  end
  
  def turn?(player)
    player == player_taking_turn
  end
  
  def player_taking_turn
    @players[@turn]
  end

  def next_turn
    @turn = @turn + 1
    @turn = 0 if @turn > (@players.length - 1)
  end

  # 2 player only
  def find_opponent(player)
    result = @players.select {|p| player.name.downcase != p.name.downcase}
    result.empty? ? nil : result.first
  end

  # 2 player only
  def player_not_taking_turn
    find_opponent(player_taking_turn)
  end
  
  def start
    @turn = rand(@players.length)
  end
  
  def destroy
    @@games.delete_if {|g|g == self}
  end
  
  def self.save
    f = File.new("data/games.yml", "w")
    f.puts YAML.dump(@@games)
    f.close
  end
  
  def self.load
    if FileTest.exist?("data/games.yml") 
      f = File.new("data/games.yml", "r")
      @@games = YAML.load(f.read)
      f.close
    end
  end
end
