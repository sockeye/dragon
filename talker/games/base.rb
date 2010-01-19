module Commands
  define_command 'games' do
    buffer = title_line("Games") + "\n"
    if Game.games.length > 0
      Game.games.each do |game|
        buffer += "  " + game.description + "\n"
      end
    else
      buffer += "  There are no games in progress.\n"
    end
    buffer += blank_line
    output buffer
  end
  
  define_command 'dice' do
    num_word = %w{One Two Three Four Five Six}
    faces = [["     ", "  *  ", "     "],
             ["*    ", "     ", "    *"],
             ["*    ", "  *  ", "    *"],
             ["*   *", "     ", "*   *"],
             ["*   *", "  *  ", "*   *"],
             ["*   *", "*   *", "*   *"]]
    
    roll1 = rand(6)
    roll2 = rand(6)
    score = roll1 + roll2 + 2
    
    double_text = [
      "Snake ears, Double Ones!",
      "Stirling Moss, Double Twos",
      "Milton Keynes, Double Threes",
      "Uncle Monty, Double Fours",
      "Snake eyes, Double Fives",
      "Good Role, Double Sixes"
    ]
    
    result_text = if roll1 == roll2
      double_text[roll1]
    else
      "A #{num_word[roll1]} and a #{num_word[roll2]}"
    end
    
    output "   ^B-------     -------       ^NYou roll two dice and get:
  ^B| ^Y#{faces[roll1][0]}^B |   | ^Y#{faces[roll2][0]}^B |      ^N#{result_text}
  ^B| ^Y#{faces[roll1][1]}^B |   | ^Y#{faces[roll2][1]}^B |^N
  ^B| ^Y#{faces[roll1][2]}^B |   | ^Y#{faces[roll2][2]}^B |      ^NTotal Score: #{score}
   ^B-------     -------^N"
  end
  define_alias 'dice', 'roll', 'd'
  
  define_command 'coin' do
    if money <= 0
      output "You can't afford to play."
    else
      self.money -= 1
      chance = rand(25000)

      if chance < 12500
        output "^Y          .-'''''-.\n        .'         `.\n       :   |@++@|    :		^n^LYou flip the coin and you get:\n^Y      :    00  o >    :\n      :   00)   =/    :		^GH E A D S\n^Y       :  O zzzz}    :\n        `.         .'\n          `-.....-'^n\n"
      elsif chance > 12500
        output "^Y          .-'''''-.\n        .'    |    `.\n       :   {-----}   :	        ^n^LYou flip the coin and you get:\n^Y      :   oo#####oo   :\n      :   o ##### o   :        ^R T A I L S\n ^Y      :  o ##### o  :\n        `.         .'\n          `-.....-'^n\n"
      else
        output "^Y       ___\n     .    .. 			^n^LYou flip the coin and it lands\n^Y    .  ;   ..	      	^P        on its edge.\n ^Y   .   ;  ..\n^r ..__^Y.^r____^Y..^r__..^n\n"
        output_to_all "^G->^n #{name} has been Joe Palookered! The coin landed on its edge!"
        output_to_all "^G->^n #{name} won 1,000,000 drogna"
        self.money = money + 1000000
        save
      end
    end
  end
  define_alias 'coin', 'c'

  define_command 'omnibus' do |message|
    (origin, destination, time) = get_arguments(message, 3)
    if origin.blank? || destination.blank? || time.blank?
      output "Format: omnibus <origin> <destination> <time>"
    else
      output "Sorry no bus service at that time."
    end
  end

end