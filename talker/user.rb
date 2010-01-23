# encoding: utf-8
class User
  include Helpers
  
  attr_accessor :name
  attr_accessor :gender
  attr_accessor :first_seen
  attr_accessor :last_activity
  attr_accessor :last_login
  attr_accessor :total_time
  attr_accessor :total_connections
  attr_accessor :colour

  attr_accessor :prompt
  attr_accessor :title

  attr_accessor :connect_message
  attr_accessor :disconnect_message
  attr_accessor :reconnect_message

  attr_accessor :money
  attr_reader :rank
  attr_accessor :debug

  attr_accessor :id, :handler, :ip_address, :charset

  attr_accessor :idle_message, :muffled

  RANK = ['Peasant', 'Farmer', 'Knight', 'Baron', 'Earl', 'Princess', 'King']
  RANK_COLOUR = ['', '^y', '^Y', '^G', '^C', '^P', '^R']

  def initialize(name)
    @name = name
    @first_seen = @last_activity = Time.now
    @total_connections = 0
    @total_time = 0
    @money = 0
    @rank = 0
    @colour = :ansi
    @muffled = false
  end

  def lower_name
    name.downcase
  end

  def password=(password)
    @password = password.crypt("el")
  end

  def password_matches?(attempt)
    @password == attempt.crypt("el")
  end

  def crypted_password=(crypted_password)
    @password = crypted_password
  end

  def resident?
    !@password.nil?
  end
  
  def save
    f = File.new(data_file_name, "w")
    f.puts YAML.dump(self)
    f.close 
  end
  
  def delete
    File.delete(data_file_name) if FileTest.exist?(data_file_name)
  end

  def developer?
    ["thebear", "felix"].include?(lower_name)
  end

  def complete_login(connection)
    old_id = @id
    @id = connection.id
    @total_connections = @total_connections + 1
    @last_activity = @last_login = Time.now
    @ip_address = connection.ip_address
    @muffled = false
    
    if resident?
      output get_text("changes")      
    else
      output get_text("welcome_newuser")
    end

    old_connection = connections[old_id]

    if old_connection.nil?
      output_to_all "^g>^G> ^n#{name} #{get_connect_message} ^G<^g<^n"
      connected_users[lower_name] = self
      output "\n^g>^G> ^nWelcome to Dragon World ^G<^g<^n\n"
    else
      old_connection.output "[Reconnection from #{connection.ip_address}]"
      old_connection.disconnect
      output_to_all "^Y>^y< ^n#{name} #{get_reconnect_message} ^y>^Y<^n"
    end
    
    look
    user_prompt
  end

  def authenticate_for_change_password(password)
    if password_matches?(password)
      output "Please enter a new password."
      send_prompt "New Password > "
      self.handler = :change_password
    else
      output "Sorry, Incorrect password!"
      self.handler = nil
      password_mode :off
    end
  end
  
  def change_password(password)
    if password.length < 3 || password.length > 8
      output "New password must be between 3 and 8 characters long!"
      send_prompt "New Password > "
    else
      was_resident = resident?
      self.password = password
      save
      if !was_resident
        output "Thank you for setting a password. Your name is now reserved for future visits."
        output_to_all "^G-> ^n#{name} becomes a saved user!"
      else
        output "Password Changed."
      end
      self.handler = nil
      password_mode :off
    end
  end

  def logout
    connected_users.delete(lower_name)
    @id = nil
    output_to_all "^R<^r< ^n#{name} #{get_disconnect_message} ^r>^R>^n"
    
    if !resident?
      delete
    else
      save
    end
  end

  def logged_in?
    !@id.nil?
  end

  def active?
    idle_time < 5400
  end

  def gender_text
    gender ? gender.to_s : 'none'
  end

  def get_prompt
    @prompt || "(dragon) "
  end

  def get_connect_message
    @connect_message || "connects"
  end

  def get_disconnect_message
    @disconnect_message || "leaves"
  end

  def get_reconnect_message
    @reconnect_message || "reconnects"
  end

  def user_prompt
    send_prompt(get_prompt)
  end

  def handle_input(input_string)
    @input_string = input_string
    if handler
      send(handler, input_string)
    else
      unless input_string.empty?
        @idle_message = nil

        (command_name, body) = split_input(input_string)
    
        command = find_command(command_name.downcase)
        if command
          command.execute(self, (body || "").gsub(/(\^+)$/, '').strip)
        end
      
        @last_activity = Time.now
      end
    end
    user_prompt if handler.nil?
    @input_string = nil
  end

  def execute_parent_command(parent_name)
    c = find_command(parent_name)
    (command_name, body) = split_input(@input_string)
    c.execute(self, body, :sub_command => false)
  end


  def idle_time
    Time.now - self.last_activity
  end
  
  def login_time
    Time.now - self.last_login
  end

  def promote!
    if can_afford_promotion? && rank < 6
      self.money -= next_rank_cost
      @rank += 1
    end
  end
  
  def demote!
    @rank -= 1 if @rank > 0
  end
  
  def next_rank_cost
    1000000 * (2 ** rank)
  end
  
  def can_afford_promotion?
    money >= next_rank_cost
  end

  def rank_name
    RANK[rank]
  end
  
  def rank_name_with_colour
    "#{RANK_COLOUR[rank]}#{RANK[rank]}^n"
  end

  def cname
    "#{RANK_COLOUR[rank]}#{name}^n"
  end
  
  def examine
    buffer = "      First seen : #{first_seen}\n"
    if logged_in?
      buffer += "      Login time : #{time_in_words(login_time)}\n"
      buffer += "       Idle time : #{time_in_words(idle_time)}\n"
      buffer += "Total login time : #{time_in_words(total_time + login_time)}\n"
    else
      buffer += "Total login time : #{time_in_words(total_time)}\n"
    end
    buffer += "     Connections : #{total_connections}\n"
    buffer += "            Rank : #{rank_name_with_colour}\n"
    buffer += "          Drogna : #{money}\n"
    buffer
  end
  
  def self.load(name)
    lower_name = name.downcase
    if FileTest.exist?("data/users/#{lower_name}.yml") 
      f = File.new("data/users/#{lower_name}.yml", "r")
      user = YAML.load(f.read)
      f.close
    end
    user
  end

  def self.add(name, connection_id)
    u = User.new
    u.name = name
    u.connection_id = connection_id
    u.save
    @users[name.downcase] = u
  end

  def self.load_all
    users = {}
    Dir["data/users/*.yml"].each do |file_name|
      f = File.new(file_name, "r")
      name = File.basename(file_name, ".yml")
      users[name] = User.load(name)
      f.close
    end
    users
  end

  def self.import
    IO.readlines("import/users/userids").each do |line|
      (name, id) = line.strip.split(' : ')
      if FileTest.exist?("import/users/#{id}.user")
        puts "#{name}/#{id}"
        u = User.new(name)
        IO.readlines("import/users/#{id}.user").each do |line|
          (field, value) = line.strip.split(' : ')
          case field
          when "password" then u.crypted_password = value
          when "first_save_stamp" then u.first_seen = Time.at(value.to_i)
          when "total_time" then u.total_time = value.to_i
          when "total_connections" then u.total_connections = value.to_i
          when "prompt" then u.prompt = value
          when "title" then u.title = value
          when "gronda" then u.money = value.to_i
          when "gender" then u.gender = value == "2" ? :male : (value == "1" ? :female : nil)
          when "debug" then u.debug = (value.to_i > 0)
          end
        end
        u.save
      end
    end
  end
  
  private

  def split_input(string)
    if string =~ /(^\W)/
      [$1.strip, string.sub(/(^\W)/,'')]
    else
      string.split(' ', 2)
    end
  end

  def data_file_name
    "data/users/#{lower_name}.yml"
  end  
end
