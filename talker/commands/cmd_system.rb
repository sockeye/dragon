module Commands
  define_command 'commands' do
    output title_line("Commands") + "\n" + Commands.names.join(", ") + "\n" + blank_line
  end

  define_command 'socials' do
    output title_line("Socials") + "\n" + Social.names.join(", ") + "\n" + blank_line
  end
  
  define_command 'changes' do 
    output Textfile.get_text "changes"
  end
  
  define_command 'testcard' do 
    output Textfile.get_text "testcard"
  end

  define_command 'pine' do 
    output Textfile.get_text "pine"
  end

  define_command 'rules' do |name|
    if name.blank?
      output "Format: rules <game>"
    else
      text = Textfile.get_text "rules_#{name.downcase}"
      if text.blank?
        output "Sorry, there are no rules for #{name}"
      else
        output text
      end
    end
  end
  
  define_command 'version' do
    output "#{Talker::NAME} - Version #{Talker::VERSION}\n"
  end
  
  define_command 'idea' do |string|
    if string.blank?
      output "Format: idea <message>"
    else
      log 'idea', "#{self.name} #{string}"
      output "That's an excellent idea, thanks a lot."
    end
  end

  define_command 'bug' do |message|
    if message.blank?
      output "Format: bug <message>"
    else
      log 'bug', "#{self.name} #{message}"
      output "Thank you, Merlin will look in to that as soon as possible."
    end
  end

  define_command 'quit' do
    output "Goodbye #{name}"
    disconnect
  end

  define_command 'time' do
    output Time.now.strftime("Server time is %I:%M %p, %A %d %B %Y") + "\n\nTelnet is #{time_in_words(Time.now - Time.mktime(1969, 9, 25, 0, 0, 0, 0))} old"
  end

  define_command 'examine' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
    if target
      if target.class == User
        buffer = title_line(target.name) + "\n"
        buffer += "      First seen : #{target.first_seen}\n"
        if target.logged_in?
          buffer += "      Login time : #{time_in_words(target.login_time)}\n"
          buffer += "       Idle time : #{time_in_words(target.idle_time)}\n"
          buffer += "Total login time : #{time_in_words(target.total_time + target.login_time)}\n"
        else
          buffer += "Total login time : #{time_in_words(target.total_time)}\n"
        end
        buffer += "     Connections : #{target.total_connections}\n"
        buffer += "            Rank : Dock Worker\n"
        buffer += "          Drogna : #{target.money}\n"
        buffer += blank_line
      else
        buffer = title_line("Social #{target.name}") + "\n"
        buffer += "^LUntargeted^n\n#{target.notarget.gsub(/\^/, '^^')}\n" if !target.notarget.blank?
        buffer += "^LTargeted^n\n#{target.target.gsub(/\^/, '^^')}\n" if !target.target.blank?
        buffer += blank_line        
      end
      output buffer
    end
  end
  define_alias 'examine', 'finger', 'profile'

  define_command 'who' do
    output title_line("Who") + "\n" +
      active_users.map { |u| sprintf("%15.15s #{u.title}", u.name) }.join("\n") + "\n" + 
      blank_line
  end
  define_alias 'who', 'w'

  define_command 'connections' do
    output title_line("Connections") + "\n" +
      active_users.map { |u| sprintf("%-15.15s #{u.ip_address}", u.name) }.join("\n") + "\n" + 
      blank_line
  end
  define_alias 'connected', 'lsi'

  define_command 'idle' do |user_name|
    if !user_name.blank?
      u = find_connected_user(user_name)
      if u
        buffer = "  #{u.name} is #{time_in_words(u.idle_time)} inactive." 
        buffer += "\n  > #{u.idle_message}^n" unless u.idle_message.blank?
        output buffer
      end
    else
      buffer = title_line("User Activity") + "\n"
      active_users.each do |u|
        bars = sprintf("%-45s", ('=' * (((5400 - u.idle_time) / 120)+1)) + " #{u.idle_message}")
        buffer += sprintf("%15.15s ^C|^R#{bars.slice(0,15)}^C|^Y#{bars.slice(15,15)}^C|^G#{bars.slice(30,15)}^C| ^c#{short_time(u.idle_time)}^n\n", u.name)
      end
      buffer += blank_line
      output buffer
    end
  end
  define_alias 'idle', 'active'

end