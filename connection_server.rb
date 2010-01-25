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
      @buffer = ""
      @channel = ReceiveFromTalker.subscribe do |data| 
        data.split("\n").each {|line| process_talker_message(line)}
      end
      (@port, *ip) = (get_peername[2,6].unpack "nC4")
      @ip = ip.join('.')
      SendToTalker << "#{signature} connection #{@ip}\n"
    end

    def process_talker_message(line)
      (recipient, command, message) = line.split(/ /, 3)
      if recipient.to_i == signature
#        puts "Processing #{line.dump}"
        case command
        when "disconnect"
          close_connection_after_writing
        when "send"
          send_data message.gsub("\\n", "\r\n")
        end
      end
    end

    def receive_data(data)
      data.each_char do |c|
        if c == "\n"
          SendToTalker << "#{signature} input #{@buffer}\n"
          @buffer = ""
        else
          @buffer += c unless c == "\r"
        end
      end
    end

    def unbind
      SendToTalker << "#{signature} disconnection\n"
      ReceiveFromTalker.unsubscribe @channel
      puts "Telnet connection closed"
    end
  end
  TelnetServer.start("0.0.0.0", 4000)

  class TalkerConnection < EM::Connection
    @@boot_count = 0

    def self.boot_talker
      puts "[Booting talker]"
      @pid = fork do
        exec("bash -c 'ruby19 talk_server.rb 2>>logs/crash.log'")
      end
      Process.detach(@pid)
    end

    def self.start
      @@timer = nil
      trying = finished = false
      until finished
        begin
          EM.connect_unix_domain "socket", TalkerConnection
          finished = true
        rescue
          if !trying
            trying = true
            boot_talker
            @@timer = EventMachine::PeriodicTimer.new(5) do
              boot_talker
            end
          end
          sleep 1
        end
      end
    end
    
    def post_init
      @@timer.cancel unless @@timer.nil?
      puts "[Established connection with talker]"
      @@boot_count += 1
      @channel = SendToTalker.subscribe { |m| send_data m }
      send_data "0 reset\n" if @@boot_count == 1
      send_data "0 uptime #{TelnetServer.boot_time}\n"
    end

    def receive_data data
      data.split("\n").each {|line|
        EM.next_tick { EM.stop_event_loop } if line == "0 shutdown"
      }
      ReceiveFromTalker << data
    end

    def unbind
      SendToTalker.unsubscribe @channel
      EM.defer proc {TalkerConnection.start}
    end
  end
  EM.defer proc {TalkerConnection.start}
}
