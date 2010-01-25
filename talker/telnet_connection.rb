# encoding: utf-8
require 'time'

module TelnetConnection
  def post_init
    $stderr.puts "#{Time.now} [Established connection with communication server]"
    @talker  = Talker.instance
    
    # data is sent from the talker to the output channel, 
    # this is forwarded to the telnet server
    @talker.output.subscribe do |data| 
      send_data data + "\n"
    end
    @talker.debug_message "Talk server loaded"
  end

  def parse_telnet(signature, data) # minimal Telnet
    data.gsub!(/([^\015])\012/, "\\1") # ignore bare LFs
    data.gsub!(/\015\0/, "") # ignore bare CRs
    data.gsub!(/\0/, "") # ignore bare NULs

    while data.index(Regexp.new('\377', nil, 'n')) # parse Telnet codes
      $stderr.puts "IAC FROM #{signature} #{data.dump}"
      if data.sub!(Regexp.new('(^|[^\377])\377[\375\376](.)', nil, 'n'), "\\1")
      # answer DOs and DON'Ts with WON'Ts
      send_data("#{signature} send \377\374#{$2}\n") unless $2 == "\001" # unless TELOPT_ECHO
      elsif data.sub!(Regexp.new('(^|[^\377])\377[\373\374](.)', nil, 'n'), "\\1")
      # answer WILLs and WON'Ts with DON'Ts
      send_data("#{signature} send \377\376#{$2}\n")
      elsif data.sub!(Regexp.new('(^|[^\377])\377\366', nil, 'n'), "\\1")
      # answer "Are You There" codes
      send_data("#{signature} send Still here, yes.\n")
      elsif data.sub!(Regexp.new('(^|[^\377])\377\364', nil, 'n'), "\\1")
      # do nothing - ignore IP Telnet codes
      elsif data.sub!(Regexp.new('(^|[^\377])\377[^\377]', nil, 'n'), "\\1")
      # do nothing - ignore other Telnet codes
      elsif data.sub!(Regexp.new('\377\377', nil, 'n'), "\377")
      # do nothing - handle escapes
      end
    end
  end

  def receive_data(data)
    data.split("\n").each do |line|
      (signature, command, message) = line.strip.split(' ', 3)

      case command
      when "reset"
        $stderr.puts "#{Time.now} RESET"
        @talker.disconnect_all
      when "uptime"
        $stderr.puts "#{Time.now} UPTIME"
        Talker.instance.connection_server_uptime = Time.parse(message)
      when "connection"
        $stderr.puts "#{Time.now} CONNECTION #{message}"
        @talker.connection(signature, message)
      when "disconnection"
        $stderr.puts "#{Time.now} DISCONNECTION #{message}"
        @talker.disconnection(signature)
      when "input"
        message ||= ""
        original_length = message.length
        parse_telnet(signature, message)
        @talker.input(signature, message.force_encoding('utf-8')) unless original_length > 0 && message.length == 0
      end
    end
  end

  def unbind
    $stderr.puts "#{Time.now} [Lost connection]"
  end
end
