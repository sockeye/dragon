# encoding: utf-8
module Commands
  define_command 'commands' do
    output title_line("Commands") + "\n" + Commands.names.join(", ") + "\n" + blank_line
  end

  define_command 'changes' do 
    output title_line("Recent Changes") + "\n" + get_text("changes") + "\n" + blank_line
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
      if string.downcase =~ /sword/
        output "Sorry, that idea is shit"
      else
        output "That's an excellent idea, thanks a lot."
      end
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
    output (title_line("#{target.class.name} #{target.name}") + "\n" + target.examine + blank_line) if target
  end
  define_alias 'examine', 'finger', 'profile', 'x', 'f'

  define_command 'settings' do |target_name|
    target = target_name.blank? ? self : find_entity(target_name)
    if target
      buffer = title_line("Settings for #{target.name}") + "\n"
      buffer += "      Title : #{target.name} #{target.title}^n\n"
      buffer += "      Login : ^g>^G> ^n#{target.name} #{target.get_connect_message} ^G<^g<^n\n"
      buffer += " Disconnect : ^R<^r< ^n#{target.name} #{target.get_disconnect_message} ^r>^R>^n\n"
      buffer += "  Reconnect : ^Y>^y< ^n#{target.name} #{target.get_reconnect_message} ^y>^Y<^n\n"
      buffer += "     Prompt : #{target.get_prompt}^n\n"
      buffer += blank_line
      output buffer
    end
  end

  define_command 'who' do
    output title_line("Who") + "\n" +
      active_users.map { |u| sprintf("%15.15s #{u.title}^n", u.name) }.join("\n") + "\n" + 
      blank_line
  end
  define_alias 'who', 'w'

  define_command 'whod' do
    output title_line("Who Debug") + "\n" +
      active_users.map { |u| sprintf("%15.15s [#{(u.charset || "ascii").to_s}]#{u.debug ? ' [Debug]' : ''}#{u.show_timestamps ? ' [Timestamps]' : ''}^n", u.name) }.join("\n") + "\n" + 
      blank_line
  end
  define_alias 'who', 'w'

  define_command 'connections' do
    output title_line("Connections") + "\n" +
      connected_users.values.map { |u| 
        c = u.active? ? "^G+" : "^W@"
        sprintf(" #{c}^n %-15.15s #{short_time(u.idle_time)} #{u.ip_address}", u.name) }.join("\n") + "\n" + 
      blank_line
  end
  define_alias 'connections', 'connected', 'lsi'

  define_command 'look' do
    look
  end
  define_alias 'look', 'l'

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
        bars = sprintf("%-45s", ("\u{25a0}" * (((5400 - u.idle_time) / 120)+1)) + " #{u.idle_message}")
        buffer += sprintf("%15.15s ^C|^R#{bars.slice(0,15)}^C|^Y#{bars.slice(15,15)}^C|^G#{bars.slice(30,15)}^C| ^c#{short_time(u.idle_time)}^n\n", u.name)
      end
      buffer += blank_line
      output buffer
    end
  end
  define_alias 'idle', 'active'

  define_command 'help' do
    buffer = title_line("Help")
    buffer += "
^cBasic talker commands:^n
^Lsay^n      Speak to everyone
^Lemote^n    Perform an action to everyone
^Lwho^n      Get a list of people who are connected
^Ltell^n     Speak to someone privately
^Lcommands^n List all the available commands
^Lsocials^n  List all the available socials (user defined actions)
^Lexamine^n  Get details about a user or social
^Lidle^n     Show when users were last active
^Lpassword^n Set and password and reserve your user name for future visits
"
    buffer += blank_line
    output buffer
  end
  define_alias 'help', '?'
  
  define_command 'uptime' do
    buffer = "Connection server uptime: #{time_in_words(Time.now - Talker.instance.connection_server_uptime)}\n"
    buffer += "Talk server uptime: #{time_in_words(Time.now - Talker.instance.talk_server_uptime)}"
    output buffer
  end 

  define_command 'muffle' do
    self.muffled = !muffled
    
    if muffled
      buffer = "^Y<-^n #{name} wear ear muff ^Y->^n"
      output_to_all buffer
      output buffer
    else
      output_to_all"^Y->^n #{name} remove ear muff ^Y<-^n"
    end
  end

  define_command 'password' do
    if !resident? && login_time < 300
      output "Sorry, you need to be logged in for at least 5 minutes to set a password."
    else
      password_mode :on
      if resident?
        output "Please enter your current password."
        send_prompt "Old Password > "
        self.handler = :authenticate_for_change_password
      else
        output "Please enter a new password."
        send_prompt "New Password > "
        self.handler = :change_password
      end
    end
  end
  define_alias 'password', 'passwd'

  define_command 'history' do
    output title_line("History") + "\n" + talker_history.to_s + "\n" + blank_line
  end
  define_alias 'history', 'recall', 'review'

  define_command 'myhistory' do
    output title_line("Your Private History") + "\n" + history.to_s + "\n" + blank_line
  end
  define_alias 'myhistory', 'rhistory'

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
  
  define_command 'social pull' do |social_name|
    if social_name.blank?
      output "Format: social pull <social name>"
    elsif valid_name?(social_name, :allow_bad_words => true)
      social_name.downcase!
      buffer = ""
      creator = ""
      begin
      result = open("http://wooooooooooooooy.com/socials/#{social_name}.txt") do |f|
        f.each_line do |line|
          buffer += line
          if line =~ /^creator/
            (token, value) = line.split(':', 2)
            creator = value.strip.downcase
          end
        end
      end
      rescue Exception => e
        if e.class == OpenURI::HTTPError && e.io.status[0] == "404"
          output "'#{social_name}' isn't on wooooooooooooooy.com."
        else
          debug_message "#{name} failed to pull social '#{social_name}': #{e}"
          output "Sorry, an error occurred when trying to pull the social. Please try again later."
        end
      else
        if creator != lower_name
          output "Sorry, only the creator can pull the social."
        else
          update = Social.socials.has_key?(social_name)

          File.open("import/socials/#{social_name}", "w") do |file|
            file.puts buffer
          end
          Social.import("import/socials/#{social_name}")
          if update
            debug_message "Social '#{social_name}' updated by #{name}"
            output "The social has been updated."
          else
            output_to_all "^Y\u{25ba}^n #{cname} creates the ^L#{social_name}^n social"
          end
        end
      end
    end
  end
  
  define_command 'social liquidate' do |social_name|
    if social_name.blank?
      output "Format: social liquidate <social name>"
    elsif social = find_social(social_name)
      if !social.created_by?(self)
        output "You need a full controlling share to liquidate the asset."
      else
        output "You have liquidated the social '#{social.name}'"
        social.delete
      end
    end
  end
  
  define_command 'socials' do |user_name|
    if user_name.blank?
      output title_line("Socials") + "\n" + Social.names.join(", ") + "\n" + blank_line
    elsif user = find_user(user_name)
      output title_line("Socials Owned By #{user.name}") + "\n" + Social.socials_by(user).map{|s| s.name}.join(", ") + "\n" + blank_line
    end
  end
  
end