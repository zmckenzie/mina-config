puts File.dirname(__FILE__)
puts Dir["#{File.dirname(__FILE__)}/tasks/*.rake"]

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].each do |task|
  puts task
  load task
end