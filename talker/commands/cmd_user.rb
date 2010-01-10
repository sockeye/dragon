module Commands
  define_command 'idlemsg' do |message|
    if message.blank?
      output "Format: idlemsg <message>"
    else
      self.idle_message = message
      output "You set your idle message to:\n^L #{name} is inactive> #{idle_message}^n"
    end
  end
  
  define_command 'title' do |message|
    if message.blank?
      self.title = ""
      output "You now have no title"
    else
      self.title = message.slice(0, 60)
      output "Your title is now:\n#{name} #{title}^n"
    end
    save
  end
  
  define_command 'gender' do |message|
    changed = true
    if message == "male"
      self.gender = :male
    elsif message == "female"
      self.gender = :female
    elsif message == "none"
      self.gender = nil
    else
      changed = false
    end
    if changed
      output "Your gender has been set to #{gender_text}."
    else
      output "Your gender is #{gender_text}, to change it type ^Lgender <female|male|none>^n"
    end
    save
  end

  define_command 'prompt' do |message|
    if message.blank?
      self.prompt = nil
      output "You will now receive the default prompt"
    elsif message == "off"
      self.prompt = ""
      output "You will no longer receive a prompt"
    else
      self.prompt = message
      output "Prompt changed"
    end
    save
  end
  
  define_command 'colour' do |message|
    if message == "on"
      self.colour = :ansi
      output "^YColour output is on!^n"
    elsif message == "off"
      self.colour = :off
      output "Colour output is off"
    elsif message == "wands"
      self.colour = :wands
      output "You are now viewing colour wands."
    else message.blank?
      output "Format: colour [on|off|wands]"
    end
    save
  end
  define_alias 'colour', 'color'
  
  define_command 'recap' do |message|
    if message.blank? || message.downcase != lower_name
      output "Format: recap <your username in lower or uppercase letters>"
    else
      self.name = message
      output "Your name is now capitalised as #{name}."
      save
    end
  end
end