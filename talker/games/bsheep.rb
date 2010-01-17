class BattlesheepPlayer < Player
  def initialize(user, state)
    super(user, state)
    create_board
  end
  
  def accept
    self.state = :accepted if state.nil?
  end
  
  def not_accepted?
    state.nil?
  end

  def accepted?
    state == :accepted
  end
  
  def ready
    self.state = :ready if state == :accepted
  end
  
  def not_ready?
    state != :ready
  end
  
  def ready?
    state == :ready
  end

  def create_board
    self.data[:board] = (0..7).map {|i|[].fill(0, 0..7)}
    randomise_board
  end
  
  def randomise_board
    # reset the board
    (0..7).each {|i|self.data[:board][i].fill(0)}
    
    # select positions
    count = 1
    [4,3,3,2,2,2].each do |l|

      done = false
      while !done
        dir = rand(2)
        x = dir == 0 ? rand(9 - l) : rand(8)
        y = dir == 0 ? rand(8)     : rand(9 - l)

        done = true
        if dir == 0
          (0..(l-1)).each {|b| done = false if data[:board][x + b][y] != 0}
        else
          (0..(l-1)).each {|b| done = false if data[:board][x][y + b] != 0}
        end
      end
        
      if dir == 0
        (0..(l-1)).each {|b| self.data[:board][x + b][y] = count}
      else
        (0..(l-1)).each {|b| self.data[:board][x][y + b] = count}
      end
      count = count + 1
    end
  end

  def attacked?(x, y)
    data[:board][x][y] >= 10
  end
  
  def attack(x, y)
    self.data[:board][x][y] += 10
  end
  
  def miss?(x, y)
    data[:board][x][y] == 10
  end

  def sheep_alive?(x, y)
    data[:board].flatten.include?(data[:board][x][y] - 10)
  end
  
  def preboard
    buffer = "\n   ^cA B C D E F G H\n"
    (0..7).each do |i|
      buffer += '   ' + render_my_line(data[:board][i])
      case i
      when 0 then buffer += "      ^YB a t t l e   S h e e p"
      when 2 then buffer += "      ^pSelect herd grazing positions"
      when 4 then buffer += "      ^nUse ^Wbsh random^n to randomize the herd grazing positions"
      when 5 then buffer += "      ^nand ^Wbsh ready^n once you have made your selection"
      end
      buffer += "^n\n"
    end
    buffer
  end

  def board(opponent)
    buffer = "\n   ^cA B C D E F G H                      A B C D E F G H\n"
    (0..7).each do |i|
      buffer += " ^c#{i + 1} #{render_opponent_line(opponent.data[:board][i])}                    ^c#{i + 1} #{render_my_line(data[:board][i])}\n"
    end
    buffer
  end

  def postboard(opponent)
    buffer = "\n   ^cA B C D E F G H                      A B C D E F G H\n"
    (0..7).each do |i|
      buffer += " ^c#{i + 1} #{render_my_line(opponent.data[:board][i])}                    ^c#{i + 1} #{render_my_line(data[:board][i])}\n"
    end
    buffer
  end

  def render_my_line(data)
    data.map do|i| 
      if i == 0
        "^g-"
      elsif i < 10
        "^W@"
      elsif i == 10
        "^d="
      else
        "^RX"
      end
    end.join(' ') + "^n"
  end
  
  def render_opponent_line(data)
    data.map do|i| 
      if i < 10
        "^g?"
      elsif i == 10
        "^d="
      else
        "^RX"
      end
    end.join(' ') + "^n"
  end
  
end

class Battlesheep < Game
  def initialize(creator, opponent)
    super()
    @players << BattlesheepPlayer.new(creator, :accepted)
    @players << BattlesheepPlayer.new(opponent, nil)
  end
  
  def self.find(user)
    super(user, 'Battlesheep')
  end
  
  def description
    "#{@players[0].name} and #{@players[1].name} are playing Battlesheep"
  end
    
  def challenger
    @players.first
  end

  def accepted?(user)
    p = player(user)
    p && p.state != nil
  end
  
  def accept(user)
    p = player(user)
    if p && p.state.nil?
      p.state = :accepted
    end
  end
    
  def get_move(string)
    if (string.downcase =~ /([a-h])([1-8])/) == 0
      [$2.to_i - 1, $1.ord - 97]
    else
      [nil, nil]
    end
  end
end

module Commands
  define_command 'bsh' do |message|
    game = Battlesheep.find(self)
    if game.nil?
      if message.blank?
        output "Format: bsh <opponent name>"
      else
        opponent = find_connected_user(message)
        if opponent
          game = Battlesheep.find(opponent)
          if game
            output "Sorry, that user is already playing a game of Battlesheep."
          else
            game = Battlesheep.new(self, opponent)
            opponent.output "^G-> ^n#{name} has challenged you to a game of Battlesheep\n^LType 'bsh accept' or 'bsh decline'.^n"
            output Textfile.get_text("rules_bships") + "\nYou challenge #{opponent.name} to a game of Battlesheep."
          end
        end
      end
    else
      p = game.player(self)
      opp = game.find_opponent(p)
      if p.not_accepted?
        output "Waiting for you to accept the challenge."
      elsif opp.not_accepted?
        output "Waiting for #{opp.name} to accept the challenge."
      elsif p.not_ready?
        output p.preboard
      elsif opp.not_ready?
        output "Waiting for #{opp.name} to select a layout."
      elsif !game.turn?(p)
        output p.board(opp) + "It is Farmer #{opp.name}'s turn."
      else
        if message.blank?
          output p.board(opp) + (game.turn?(p) ? "It is your turn." : "It is Farmer #{opp.name}'s turn.")
        else
          (x, y) = game.get_move(message)
          if x.nil?
            output "You must specify a grid position from a1 to h8!"
          else
            if opp.attacked?(x, y)
              output "You have already attacked those co-ordinates!" 
            else
              opp.attack(x, y)
              if opp.miss?(x, y)
                game.next_turn
                pbuffer = "^LMISS!^N It is now Farmer #{opp.name}'s turn"
                obuffer = "Farmer #{p.name} tries #{message.upcase}. ^LMISS!^N It is now your turn"
              else
                p.score = p.score + 1
                alive = opp.sheep_alive?(x, y)
                pbuffer = "You try #{message.upcase}, ^RHIT!^N #{alive ? '' : 'The sheep is dead! '}You get another turn"
                obuffer = "Farmer #{p.name} tries #{message.upcase}, ^RHIT!^N They #{alive ? '' : 'killed a sheep and '}get another turn"
              end
            
              if p.score > 15
                output p.board(opp)
                opp.output opp.postboard(p)
                pay_out = (16 - opp.score) * 10
                output_to_all "^g->^n #{p.name} beats #{opp.name} at Battlesheep, winning #{pay_out} drogna!"
                self.money += pay_out
                save
                game.destroy
              else
                output p.board(opp) + pbuffer
                opp.output opp.board(p) + obuffer
              end
            end
          end
        end
      end
    end
  end
  
  define_command 'bsh accept' do
    game = Battlesheep.find(self)
    if game.nil?
      output "You don't have a game to accept."
    else
      p = game.player(self)
      if !p.not_accepted?
        output "You have already accepted the challenge."
      else
        p.accept
        game.players.each { |p| p.output p.preboard }
      end
    end
  end
  
  define_command 'bsh decline' do
    game = Battlesheep.find(self)
    if game.nil?
      output "You don't have a game to decline."
    else
      if !game.player(self).not_accepted?
        output "You have already accepted the challenge."
      else
        game.challenger.output "#{name} declines your Battlesheep offer."
        output "You decline the Battlesheep offer from #{game.challenger.name}."
        game.destroy
      end
    end
  end
  
  define_command 'bsh random' do
    game = Battlesheep.find(self)
    if game.nil?
      execute_parent_command('bsh')
    else
      p = game.player(self)
      if p.accepted?
        p.randomise_board
        output p.preboard
      else
        output "You can't do that now."
      end
    end
  end
  
  define_command 'bsh ready' do
    game = Battlesheep.find(self)
    if game.nil?
      execute_parent_command('bsh')
    else
      p = game.player(self)
      if p.accepted?
        p.ready
                
        opp = game.find_opponent(p)
        if opp.not_ready?
          opp.output "#{name} is ready to play, waiting for you..."
          output "You are ready to play, waiting for #{opp.name}..."
        else
          game.start
          t  = game.player_taking_turn
          nt = game.player_not_taking_turn
          t.output t.board(nt) + "You get to go first."
          nt.output nt.board(t) + "Farmer #{t.name} gets to go first."
        end
      end
    end
  end
  
  define_command 'bsh quit' do
    game = Battlesheep.find(self)
    if game.nil?
      execute_parent_command('bsh')
    else
      p = game.player(self)
      opp = game.find_opponent(p)
      opp.output "#{name} has just quit your game of battlesheep!" if opp
      output "You quit your game of battlesheep."
      game.destroy
    end
  end

  define_command 'bsh cheat' do
    game = Battlesheep.find(self)
    if game.nil?
      execute_parent_command('bsh')
    else
      p = game.player(self)
      if !p.ready?
        output "You can't cheat before you've started playing!"
      else
        opp = game.find_opponent(p)
        output_to_all "^g->^n #{p.name} just tried to cheat at Battle Sheep! #{opp.name} wins!"
        game.destroy
      end
    end
  end

end