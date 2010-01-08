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

  attr_accessor :id, :handler, :ip_address

  attr_accessor :idle_message

  def initialize(name)
    @name = name
    @first_seen = @last_activity = Time.now
    @total_connections = 0
    @total_time = 0
    @money = 0
    @rank = 0
    @colour = :ansi
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
    puts "[saving user #{name}]"
    f = File.new(data_file_name, "w")
    f.puts YAML.dump(self)
    f.close 
  end
  
  def delete
    puts "[delete user #{name}]"
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
    
    if resident?
      output get_text("changes")      
    else
      output get_text("welcome_newuser")
    end

    old_connection = connections[old_id]

    if old_connection.nil?
      output_to_all "^g>^G> ^n#{name} #{connect_message || "connects"} ^G<^g<^n"
      connected_users[lower_name] = self
      output "\n^g>^G> ^nWelcome to Dragon World ^G<^g<^n\n"
    else
      old_connection.output "[Reconnection from #{connection.ip_address}]"
      old_connection.disconnect
      output_to_all "^Y>^y< ^n#{name} #{connect_message || "reconnects"} ^y>^Y<^n"
    end
    
    # output who
    user_prompt
  end

  def logout
    connected_users.delete(lower_name)
    @id = nil
    output_to_all "^R<^r< ^n#{name} #{disconnect_message || "leaves"} ^r>^R>^n"
    
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
    prompt || "(dragon) "
  end

  def user_prompt
    send_prompt(get_prompt)
  end

  def handle_input(input_string)
    unless input_string.empty?
      @idle_message = nil

      (command_name, body) = split_input(input_string)
    
      command = Commands.find(command_name.downcase)
      if command
        command.execute(self, body)
      else
        output "'#{command_name}' was not recognised as a valid command."
        log 'unknown', "#{self.name} #{command_name}"
      end
      
      @last_activity = Time.now
    end
    user_prompt if handler.nil?
  end

  def idle_time
    Time.now - self.last_activity
  end
  
  def login_time
    Time.now - self.last_login
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

#  def self.find(name)
#    Talker.instance.all_users[name.downcase]
#  end

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
          end
        end
        u.save
      end
    end
  end
  
  private

  def split_input(string)
    if string =~ /(^\W+)/
      [$1.strip, string.sub(/(^\W+)/,'')]
    else
      string.split(' ', 2)
    end
  end

  def data_file_name
    "data/users/#{lower_name}.yml"
  end  
end
