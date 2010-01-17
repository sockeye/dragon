module Commands
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
end