require 'singleton'

require 'talker/util'
require 'talker/helpers'

require 'talker/connection'
require 'talker/user'
require 'talker/textfile'

require 'talker/commands'
require 'talker/commands/cmd_system'
require 'talker/commands/cmd_user'
require 'talker/commands/cmd_comms'
require 'talker/commands/cmd_dev'
require 'talker/commands/cmd_games'

require 'talker/socials'

class Talker
  NAME    = 'Dragon World'
  VERSION = '0.7.0'
  
  include Singleton
  
  attr_accessor :connected_users, :all_users, :output, :connections,
                :talk_server_uptime, :connection_server_uptime, :shutdown
  attr_reader :current_id
  
  def initialize
    @connections = {}
    @all_users = {}
    @connected_users = {}
    @commands = {}
    @connection_server_uptime = nil
    @talk_server_uptime = Time.now
    @shutdown = false
  end
  
  def run
    @output = EM::Channel.new
    Textfile.load
    @all_users = User.load_all
    Social.import
    Commands.add_commands(Social.socials)
    
    load_connections
    @connections.values.each do |c|
      if c.logged_in?
        u = find_or_add_user(c.user_name)
        @connected_users[u.lower_name] = u
      end
    end
  end
  
  def connection(signature, ip_address)
    @connections[signature] = Connection.new(signature, ip_address)
    save
  end
  
  def disconnection(signature)
    c = @connections[signature]
    if c
      if c.logged_in? # login has finished
        u = @all_users[c.user_name.downcase]
        if u
          u.logout if u.id == c.id
          @all_users.delete(u.lower_name) if !u.resident?
        end
      end
      @connections.delete(signature)
      save
    end
  end
  
  def disconnect_all
    @connections = {}
    @connected_users = {}
    save
  end
  
  def input(signature, string)
    @current_id = signature
    string ||= ""
    c = @connections[signature]
    if c.nil?
      output << "#{signature} disconnect"
    else
      if !c.logged_in?
        c.handle_input(string)
        if c.logged_in? # login has finished
          u = find_or_add_user(c.user_name)
          u.complete_login(c)
        end
        save
      else
        u = @all_users[c.user_name.downcase]
        if u.nil?
          c.disconnect
        else
          u.handle_input(string)
        end
      end
    end
    @current_id = nil
    if @shutdown
      EM.stop_event_loop 
    end
  end
  
  def find_or_add_user(name)
    u = @all_users[name.downcase]
    if u.nil?
      u = User.new(name)
      @all_users[name.downcase] = u
    end
    u
  end
  
  def save_connections
    puts "[saving connections]"
    f = File.new("data/connections.yml", "w")
    f.puts YAML.dump(@connections)
    f.close
  end

  def save_connected_users
    @connected_users.values.each do |u|
      u.save
    end
  end

  def save
    puts "[saving]"
    save_connections
    save_connected_users
  end

  def load_connections
    if FileTest.exist?("data/connections.yml") 
      f = File.new("data/connections.yml", "r")
      @connections = YAML.load(f.read)
      f.close
    else
      @connections = {}
    end
    puts "[loaded #{@connections.keys.length} connections]"
  end

  def debug_message(message)
    @connected_users.values.select {|u|u.debug}.each { |u| u.output "^g[debug] #{message}^n" }
  end  
  
end
