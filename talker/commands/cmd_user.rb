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
      output "Your gender is #{gender_text}, to changed it type ^Lgender <female|male|none>^n"
    end
  end
      
end