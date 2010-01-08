module TalkerUtilities
  def valid_name?(name)
    len = name.length
    
    if len < 2
      output "The name must be at least 2 letters long."
      return false
    end
    
    if len > 15
      output "The name must be 15 letters or less."
      return false
    end
    
    unless name =~ /^[a-zA-Z]/
      output "The first character of the name must be a letter of the alphabet."
      return false
    end
    
    if name =~ /[^a-zA-Z0-9]/
      output "The name can only contain letters of the alphabet and numbers."
      return false
    end
    
    if %w{admin all announce bollocks cunt connect directed everyone everybody foreskin fuck games newbie newbies public private settext shit socials you }.include?(name.downcase)
      output "Sorry, that name can not be used."
      return false
    end
    true
  end
  
  ANSI_COLOURS = {
    'n' => "\033[0m",    # reset
    'N' => "\033[0m", 
    'L' => "\033[1m",    # bold
    'l' => "\033[2m",    # faint
    'u' => "\033[4m",    # underline
    'U' => "\033[4m", 
    'k' => "\033[5m",    # blink
    'K' => "\033[5m",
    'h' => "\033[7m",    # reverse
    'H' => "\033[7m",
    'd' => "\033[0;30m", # black
    'r' => "\033[0;31m", # red
    'g' => "\033[0;32m", # green
    'y' => "\033[0;33m", # yellow/brown
    'b' => "\033[0;34m", # blue
    'p' => "\033[0;35m", # purple
    'c' => "\033[0;36m", # cyan
    'w' => "\033[0;37m", # grey/white
    'D' => "\033[1;30m", # bold black
    'R' => "\033[1;31m", # bold red
    'G' => "\033[1;32m", # bold green
    'Y' => "\033[1;33m", # bold yellow
    'B' => "\033[1;34m", # bold blue
    'P' => "\033[1;35m", # bold purple
    'C' => "\033[1;36m", # bold cyan
    'W' => "\033[1;37m", # bold white
    's' => "\033[0;40m", # bg black
    'e' => "\033[0;41m", # bg red
    'f' => "\033[0;42m", # bg green
    't' => "\033[0;43m", # bg yellow
    'v' => "\033[0;44m", # bg blue
    'o' => "\033[0;45m", # bg purple
    'x' => "\033[0;46m", # bg cyan
    'q' => "\033[0;47m", # bg white
    '^' => '^'
  }.freeze
  
  RANDOM_COLOUR = {
    'a' => %w{y r c p g b w},
    'A' => %w{Y R C P G B W}
  }
  
  def colourise(string, colour_mode)
    case colour_mode
    when :ansi
      colours     = ANSI_COLOURS
    else
      colours     = {}
    end
    
    stored_string  = ""
    scanner = StringScanner.new(string)
    while match = scanner.scan_until(/\^(\S?)/)
      stored_string << match.slice(0, match.length - scanner.matched_size)
      l = scanner[1]
      l = RANDOM_COLOUR[l][rand(RANDOM_COLOUR[l].length)] if RANDOM_COLOUR.keys.include?(l)
      stored_string << colours[l] if !l.blank? && colours.keys.include?(l)
    end
    stored_string << scanner.rest if scanner.rest?
    stored_string
  end

  def commas_and(list)
    list = list.compact
    if list.empty?
      ""
    else
      last = list.pop
      list.join(", ") + (list.empty? ? last : " and #{last}")
    end
  end
  
  def pluralise(word, amount)
    "#{word}#{amount != 1 ? 's' : ''}"
  end
  
  def time_in_words(secs)
    secs = secs.to_i
    if secs == 0
      "No time at all"
    else
      buf = []
      [[31536000, "year"], [86400, "day"], [3600, "hour"], [60, "minute"]].each do |amount, name|
        i = secs / amount
        secs %= amount
        buf << pluralise("#{i} #{name}", i) if i > 0
      end
      buf << pluralise("#{secs} second", secs) if secs > 0
      commas_and(buf)
    end
  end
  
  def short_time(secs)
    secs = secs.to_i
    
    days  = secs / 86400 ; secs %= 86400
    hours = secs / 3600  ; secs %= 3600
    mins  = secs / 60    ; secs %= 60
    
    if days > 0
         sprintf "%2dd%2.2dh", days, hours
    elsif hours > 0
         sprintf "%2dh%2.2dm", hours, mins
    else
         sprintf "%2dm%2.2ds", mins, secs
    end
  end
  
  def title_line(text)
    "^B__/^Y#{text}^B\\" + ('_' * (75 - text.length)) + "^n"
  end
  
  def blank_line
    "^B" + '_' * 79 + "^n"
  end
  
end