# encoding: utf-8
class Multi
  include TalkerUtilities
  
  @@multis = []
  
  attr_reader :num
  
  def initialize(users)
    @@multis << self
    @users = users
    @num = Multi.next_num
    @last_use = Time.now
  end
  
  def self.find_or_create(users)
    if users.nil?
      nil
    else
      result = @@multis.select {|m|m.members_match?(users)}
      result.empty? ? Multi.new(users) : result.first
    end
  end
  
  def self.find(num)
    result = @@multis.select{|m| m.num == num}
    result.empty? ? nil : result.first
  end
  
  def self.next_num
    count = 1
    numbers = @@multis.map{|m|m.num}
    while numbers.include?(count)
      count = count + 1
    end
    count
  end
  
  def members_match?(users)
    @users.length == users.length && (@users.map {|u|u.name.downcase}.sort == users.map {|u|u.name.downcase}.sort)
  end
  
  def member?(user)
    @users.include?(user)
  end
  
  def users_excluding(user)
    @users.select{|u| u.lower_name != user.lower_name}
  end
  
  def output_ex(user, message)
    users_excluding(user).each { |u| u.output message }
  end

  def names_ex(user)
    commas_and(users_excluding(user).map{|u| u.cname})
  end

  def tell(from, message)
    if member?(from)
      from.output "^L(#{@num}) You say '#{message}^L' to #{names_ex(from)}"
      output_ex(from, "^L(#{@num}) #{from.cname}^L says '#{message}^L' to #{names_ex(from)}")
    end
  end
  
  def pemote(from, message)
    if member?(from)
      from.output "^L(#{@num}) You emote '#{from.cname} #{message}^L' to #{names_ex(from)}"
      output_ex(from, "^L(#{@num}) #{from.cname}^L #{message}^L (to #{names_ex(from)})")
    end    
  end
  
  def to_s
    "(#{@num}) #{commas_and(@users.map {|u| u.name})}"
  end
  
  def destroy
    @@multis.delete_if {|m| m == self}
  end
  
  def self.view
    @@multis.join("\n")
  end
end