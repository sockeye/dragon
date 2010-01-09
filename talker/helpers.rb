module Helpers
  include TalkerUtilities
    
  def output_to_all(message)
    connected_users.values.each { |u| u.output message }
  end
  
  def all_users
    Talker.instance.all_users
  end
  
  def find_user_from_hash(hash, name, options={})
    return nil if name.blank?
    lower_name = name.downcase
    u = hash[lower_name]
    if u.nil? && !options[:exact_match] # try partial match
      matches = hash.keys.select {|n| n =~ /^#{lower_name}/}
      if matches.length == 0
        output "A match for \'#{name}\' could not be found." unless options[:silent]
      elsif matches.length > 1
        output "Multiple name matches: #{matches.join(', ')}."  unless options[:silent]
      else
        u = hash[matches.first]
      end
    end
    u
  end
  
  def find_user(name, options={})
    find_user_from_hash(Talker.instance.all_users, name, options)
  end
    
  def find_connected_user(name, options={})
    find_user_from_hash(connected_users, name, options)
  end

  def find_social(name, options={})
    socials = Social.socials
    find_user_from_hash(socials, name, :silent => true)
  end

  def find_entity(name)
    type = nil
    (type, name) = name.split(' ', 2) if name =~ / /
    if type == "user"
      find_user(name)
    elsif type == "social"
      find_social(name)
    else
      e = find_user(name, :silent => true)
      e = find_social(name, :silent => true) if e.nil?
      output "A match for \'#{name}\' could not be found." if e.nil?
      e
    end
  end  

  def lookup_user(name)
    Talker.instance.all_users[name.downcase]
  end
  
  def connected_users
    Talker.instance.connected_users
  end

  def active_users
    connected_users.values.select {|u| u.active?}
  end
  
  def output(message)
    buffer = "\r\0" + colourise(message, self.colour).gsub("\n", "\\n") + "\033[0K\\n"
    buffer += get_prompt if Talker.instance.current_id != id

    raw_send buffer
  end
  
  def send_prompt(message)
    raw_send "\r\0#{message}\377\371"
  end

  def password_mode(state)  # IAC WILL ECHO  # IAC WONT ECHO
    raw_send (state == :on ? "\377\373\001" : "\377\374\001")
  end
  
  def disconnect
    Talker.instance.output << "#{id} disconnect"
  end
    
  def connections # the connected sockets
    Talker.instance.connections
  end
  
  def output_inactive_message(user)
    output " ^L #{user.name} is inactive> #{user.idle_message}^n" if !user.idle_message.blank?
  end
  
  def get_text(name)
    Textfile.get_text(name)
  end
  
  def log(log_file, text)
    File.open("logs/#{log_file}", "a") {|f| f.puts "#{Time.now.strftime("%Y-%m-%d %H:%M")} #{text}"}
  end
  
  def reboot
    if developer?
      Talker.instance.save
      exit
    end
  end
  
  def look
    num = connected_users.keys.length
    output "There #{is_are(num)} #{num} #{pluralise('user', num)} online: #{commas_and(connected_users.values.map{|u|u.name})}"
  end
  
  # send fully formatted message to a connection
  # use 'output' instead of this
  def raw_send(message)
    Talker.instance.output << "#{id} send #{message}"
  end
    
end