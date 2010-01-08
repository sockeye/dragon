class Connection
  include Helpers
  
  attr_reader :id, :ip_address
  attr_accessor :user_name

  def initialize(id, ip_address)
    @id = id
    @ip_address = ip_address
    @user_name = ""
    start_login
  end

  def start_login
    output (get_text "connect_screen.1")
    send_prompt "Please enter your nickname: "
    @login_stage = :handle_name
  end

  def handle_name(string)
    case string.downcase
    when "quit"
      disconnect
    when "who", "look"
      output "Sorry, not yet implemented"
    when "version"
      output "Sorry, not yet implemented"
    else
      if valid_name?(string)
        u = lookup_user string
        @user_name = string
        if u
          if u.resident?
            output "User exists.\n"
            ask_for_password
          else
            output "Sorry, there is already a new user connected with that name."
          end
        else
          # handle new user
          @login_stage = :completed
        end
      else
        # handle invalid name
      end
    end
    send_prompt "Please enter your nickname: " if @login_stage == :handle_name
  end

  def ask_for_password
    output "Please enter your password or press enter to choose a different name."
    send_prompt "Password: "
    password_mode(:on)
    @login_stage = :handle_password
  end

  def handle_password(string)
    if string.empty?
      send_prompt "Please enter your nickname: "
      password_mode(:off)
      @login_stage = :handle_name
    elsif string.downcase == "quit"
      disconnect
    else
      u = lookup_user @user_name
      if u.nil?
        disconnect
      else
        if u.password_matches? string
          password_mode(:off)
          @login_stage = :completed
        else
          # TODO count and log after several failed attempts
          output "Incorrect password!"
          ask_for_password
        end
      end
    end
  end

  def handle_input(string)
    send(@login_stage, string)
  end

  def logged_in?
    @login_stage == :completed
  end

  def colour
    false
  end
  
  def get_prompt
    ""
  end
end
