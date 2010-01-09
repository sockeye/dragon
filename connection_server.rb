require 'rubygems'
require 'eventmachine'

EM.run {
  SendToTalker = EM::Channel.new
  ReceiveFromTalker = EM::Channel.new
  
  class TelnetServer < EM::Connection
    def self.start(location, port)
      EM.start_server location, port, self
      @boot_time = Time.now
    end

    def self.boot_time
      @boot_time
    end

    def post_init
      puts "New Connection #{signature}"
      @prompt = ""
      @channel = ReceiveFromTalker.subscribe do |data| 
        data.split("\n").each {|line| process_talker_message(line)}
      end
      (@port, *ip) = (get_peername[2,6].unpack "nC4")
      @ip = ip.join('.')
      SendToTalker << "#{signature} connection #{@ip}"
    end

    def process_talker_message(line)
      (recipient, command, message) = line.split(/ /, 3)
      if recipient.to_i == signature
        puts "Processing #{line.dump}"
        case command
        when "disconnect"
          close_connection_after_writing
        when "send"
          send_data message.gsub("\\n", "\r\n")
        end
      end
    end

    def receive_data(data)
      lines = data == "\r\n" ? [""] : data.split("\r\n")
      lines.each do |line|
        SendToTalker << "#{signature} input #{line}\n"
      end
    end

    def unbind
      SendToTalker << "#{signature} disconnection"
      ReceiveFromTalker.unsubscribe @channel
      puts "Telnet connection closed"
    end
  end
  TelnetServer.start("0.0.0.0", 4000)

  class TalkerConnection < EM::Connection
    @@boot_count = 0
    
    def self.start
      finished = false
      until finished
        begin
          EM.connect_unix_domain "socket", TalkerConnection
          finished = true
         rescue
           puts "[Booting talker]"
           @pid = fork do
             exec("ruby talk_server.rb")
           end
           Process.detach(@pid)
           sleep 5
         end
       end
    end
    
    def post_init
     puts "[Established connection with talker]"
     @@boot_count += 1
     @channel = SendToTalker.subscribe { |m| send_data m }
     send_data "0 reset\n" if @@boot_count == 1
     send_data "0 uptime #{TelnetServer.boot_time}\n"
    end

    def receive_data data
     ReceiveFromTalker << data
    end

    def unbind
     SendToTalker.unsubscribe @channel
     TalkerConnection.start
    end
  end
  p = proc {
    TalkerConnection.start
  }
  EM.defer(p)
}
