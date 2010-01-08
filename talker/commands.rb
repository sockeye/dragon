class Command
  def initialize(name, block)
    @name = name
    @command_block = block
  end
  
  def execute(user, body)
    user.instance_exec(body, &@command_block)
  end
end

class Alias
  def initialize(name, command)
    @name = name
    @command = command
  end
  
  def execute(user, body)
    @command.execute(user, body)
  end
end

module Commands
  @command_list = {}
  @visible_command_names = []
  
  def self.define_command(name, options={}, &block)
    @command_list[name] = Command.new(name, block)
    @visible_command_names << name
  end

  def self.define_alias(command_name, *alias_names)
    alias_names.each do |alias_name|
      @command_list[alias_name] = Alias.new(alias_name, @command_list[command_name])
    end
  end
  
  def self.find(name)
    @command_list[name]
  end
  
  def self.names
    @visible_command_names.sort {|a,b|a <=> b}
  end
  
  def self.add_commands(commands)
    commands.each { |key, value| @command_list[key] = value }
  end
end