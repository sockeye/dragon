# encoding: utf-8
class String
  def blank?
    self.empty?
  end
end

class NilClass
  def blank?
    true
  end
end

#class Proc 
#  def bind(object)
#    block, time = self, Time.now
#    (class << object; self end).class_eval do
#      method_name = "__bind_#{time.to_i}_#{time.usec}"
#      define_method(method_name, &block)
#      method = instance_method(method_name)
#      remove_method(method_name)
#      method
#    end.bind(object)
#  end
#end

#class Object
#  def instance_exec(*arguments, &block)
#    block.bind(self)[*arguments]
#  end
#end
