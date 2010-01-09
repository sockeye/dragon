module Commands
  define_command 'say' do |message|
    if message.blank?
      output "Format: say <message>"
    else
      output_to_all "#{name} says '#{message}^n'"
    end
  end
  define_alias 'say', '`', '\'', '\"'
  
  define_command 'emote' do |message|
    if message.blank?
      output "Format: emote <message>"
    else
      output_to_all "#{name} #{message}^n"
    end
  end
  define_alias 'emote', ';', ':', 'emtoe', 'emoet', 'emotes', 'me'

  define_command 'echo' do |message|
    if message.blank?
      output "Format: echo <message>"
    else
      output_to_all "[#{name}] #{message}"
    end
  end
  define_alias 'echo', '+'
  
  define_command 'tell' do |message|
    (target_name, message) = get_arguments(message, 2)
    
    if message.blank?
      output "Format: tell <user(s)> <message>"
    else
      target = find_connected_user(target_name)
      if target
        format = if message =~ /\?$/
          ['ask', 'of ']
        elsif message =~ /!$/
          ['exclaim', 'to ']
        else
          ['tell', '']
        end
        target.output "^L> #{name} #{format[0]}s #{format[1]}you \'#{message}\'^n"
        output "^L> You #{format[0]} #{format[1]}#{target.name} \'#{message}\'^n"
        output_inactive_message(target)
      end
    end
  end
  define_alias 'tell', '.', 'rsay'
  
  define_command 'pemote' do |message|
    (target_name, message) = get_arguments(message, 2)
    
    if message.blank?
      output "Format: pemote <user(s)> <message>"
    else
      target = find_connected_user(target_name)
      if target
        space = message =~ /^[,']/ ? '' : ' '
        target.output "^L> #{name}#{space}#{message}"
        output "^L> #{name}#{space}#{message}"
        output_inactive_message(target)
      end
    end
  end
  define_alias 'pemote', ',', 'remote', '<'
end