# encoding: utf-8
module Commands
  define_command 'reboot' do
    if developer?
      reboot
    else
      output "No permission."
    end
  end

  define_command 'shutdown' do |message|
    if developer?
      if message.blank?
        output "Format: shutdown <message>"
      else
        output_to_all "^Y=> Shutting Down: #{message}^n"
        shutdown
      end
    else
      output "No permission."
    end
  end
  
  define_command 'multis' do
    output title_line("Multis") + "\n" + Multi.view + "\n" + blank_line
  end

  define_command 'reset_password' do |target_name|
    if developer?
      if target_name.blank?
        output "Format: reset_password <user name>"
      else
        u = find_user(target_name)
        if u
          u.crypted_password = "elZ0lon/B9mUI"
          u.save
          output "Password reset for #{u.name}."
        end
      end
    else
      output "No permission."
    end
  end
  
#  define_command 'dectest' do
#    output "\033(0 k l m n o p q r s t u v w x }\033(B"
#  end
end