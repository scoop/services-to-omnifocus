require "rubygems"
require "bundler/setup"
require "appscript"

def its
  Appscript.its
end

def update_if_changed(task, field, value)
  if task.send(field).get != value
    puts "Updating field #{field} of task #{task.name.get}"
    task.send(field).set value
  end
end
