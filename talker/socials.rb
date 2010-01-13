class Social
  @socials = {}

  attr_accessor :name, :creator, :target, :notarget
  
  def initialize(name, creator, notarget, target)
    @name     = name
    @creator  = creator
    @notarget = notarget
    @target   = target
  end
  
  def supports_targeted?
    !@target.blank?
  end
  
  def supports_untargeted?
    !@notarget.blank?
  end

  def requires_target?
    supports_targeted? && !supports_untargeted?
  end
  
  def execute(user, body)
    body ||= ""
    text = nil
    
    if supports_targeted?
      (target_name, message) = body.split(' ', 2)
      target = user.find_connected_user(target_name, :silent => true)
      if target
        text = @target
        body = message || ""
      elsif supports_untargeted?
        text = @notarget
      else
        user.output "Format: #{@name} <user>"
      end
    else
      text = @notarget
      target = nil
    end
    
    if !text.blank?
      if text =~ /<(message|S)>/ && body.blank?
        user.output "Format: #{@name} <message>"
      else
        user.output_to_all "#{user.cname} #{process_dynatext(process_randoms(text), user, target, body)}^n"
      end
    else
      user.output "Sorry, the social is down for maintenance."
    end
  end
  
  def process_randoms(text)
    stack          = []
    stored_string  = ""
    random_choices = []

    scanner = StringScanner.new(text)
    while match = scanner.scan_until(/[\{\}\|]|\[(one of|or|at random)\]/)
      stored_string << match.slice(0, match.length - scanner.matched_size)
      case scanner.matched
      when "{", "[one of]"
        stack.push([random_choices, stored_string])
        random_choices = []
        stored_string  = ""
      when "|", "[or]"
        if stack.empty?
          stored_string << "|"
        else
          random_choices.push(stored_string)
          stored_string = ""
        end
      when "}", "[at random]"
        random_choices.push(stored_string)
        selected_choice = random_choices[rand(random_choices.length)]
        (random_choices, stored_string) = stack.pop
        stored_string << selected_choice
      end
    end
    stored_string << scanner.rest if scanner.rest?
    stored_string
  end
  
  def process_dynatext(text, from, to, message)
    text = text.gsub(/<(message|S)>/i, message)

    stored_string  = ""
    scanner = StringScanner.new(text)
    while match = scanner.scan_until(/<(T|S|U)\S*:(\S+)>/)
      stored_string << match.slice(0, match.length - scanner.matched_size)
      case scanner[1].upcase
      when "S", "U"
        stored_string << process_dynatext_part(from, scanner[2])
      when "T"
        stored_string << process_dynatext_part(to, scanner[2])
      end
    end
    stored_string << scanner.rest if scanner.rest?
    stored_string
  end
  
  GENDER_WORDS = {
    "heshe" => {:male => "he", :female => "she"},
    "hisher" => {:male => "his", :female => "her"},
    "himher" => {:male => "him", :female => "her"},
    "hishers" => {:male => "his", :female => "hers"},
    "malefemale" => {:male => "male", :female => "female"},
  }
  
  def process_dynatext_part(user, type)
    gender = user.gender || :female
  
    if type == "name"
      user.name
    elsif GENDER_WORDS.include?(type)
      GENDER_WORDS[type][gender]
    else
      ""
    end
  end
  
  def examine
    buffer =  "^LCreator^n\n#{@creator.blank? ? 'Unknown' : @creator}\n" 
    buffer += "^LUntargeted^n\n#{@notarget.gsub(/\^/, '^^')}\n" if !@notarget.blank?
    buffer += "^LTargeted^n\n#{@target.gsub(/\^/, '^^')}\n" if !@target.blank?
    buffer
  end
  
  def self.import
    Dir["import/socials/*"].each do |file_name|
      name = File.basename(file_name)

      s = {}
      File.foreach(file_name) do |line|
        (token, value) = line.split(':', 2)
        s[token.strip] = value.strip if token && value
      end

#      @socials[name.downcase] = Social.new(name.downcase, s['creator'] || "", s['nonegroup'] || "", s['usergroup'] || "")
      @socials[name.downcase] = Social.new(name.downcase, s['creator'] || "", s['nt-u'] || "", s['ut-u'] || "")
    end
    
  end
  
  def self.socials
    @socials
  end
  
  def self.names
    @socials.keys.sort {|a,b|a <=> b}
  end
  
end