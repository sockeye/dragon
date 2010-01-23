# encoding: utf-8
class Textfile
  def self.load
    @textfiles = {}
    Dir["data/textfiles/*"].each do |file_name|
      f = File.new(file_name, "r")
      @textfiles[File.basename(file_name)] = f.read
      f.close
    end
  end
  
  def self.get_text(name)
    @textfiles[name] || ""
  end
end