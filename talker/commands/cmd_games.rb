module Commands
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
    
  define_command 'staff' do
    buffer = title_line('Staff') + "\n"
    (0..5).each do |i|
      rank = 6 - i
      staff_at_rank = commas_and(all_users.values.select{|u| u.rank == rank}.map {|u| u.name})
      buffer += sprintf("#{User::RANK_COLOUR[rank]}%10.10s ^n: #{staff_at_rank}\n", User::RANK[rank])
    end
    buffer += blank_line
    output buffer
  end
  
  define_command 'promote' do
    if rank > 5
      output "You are already a ^RKing^n!"
    elsif !can_afford_promotion?
      output "You need #{next_rank_cost} drogna for the next rank.^n"
    else
      promote!
      output "Thank you for the donation!"
      output_to_all "^G-> ^n#{name} has been promoted to a #{rank_name_with_colour}"
      save
    end
  end
  
  define_command 'give' do |message|
    (recipient_name, amount) = get_arguments(message, 2)
    amount = amount.to_i
    if recipient_name.blank? || amount < 1
      output "Format: give <user> <amount>"
    else
      recipient = find_connected_user(recipient_name)
      if recipient
        if amount > money
          output "You don't have that much to give."
        else
          self.money -= amount
          recipient.money += amount
          output_to_all "^g->^n #{cname} has just given #{recipient.cname} #{amount} drogna!"
          save
          recipient.save
        end
      end
    end
  end
end