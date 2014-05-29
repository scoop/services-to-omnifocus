#
# Create OmniFocus tasks for tasks assigned to you in 37signals' Highrise.
# When tasks change in Highrise, those changes are reflected in OmniFocus. This
# includes options like start and due dates as well as task titles. If you
# check off a task in OmniFocus, it is completed in Highrise. Other changes
# to tasks in OmniFocus are *not* synced back to Highrise at this point.
#
# Authentication data is taken from these environment variables:
#
#   HIGHRISE_HOST: Contains the name of the virtual host of your Highrise account
#   HIGHRISE_USER: Contains the API token of your Highrise user, found under
#                  "Account & settings" > "My info" > "API token"

require "highrise"

Highrise::Base.site = ENV['HIGHRISE_HOST']
Highrise::Base.user = ENV['HIGHRISE_USER']
Highrise::Base.format = :xml

class Highrise::Task
  def name_with_id
    "#{subject_name}: #{body} (##{id})"
  end

  def url
    return '' unless subject_id
    Highrise::Base.site.to_s + [ subject_type.downcase.pluralize, subject_id ].join('/')
  end

  def start_date
    case frame
    when 'today', 'overdue' then Date.today.midnight
    when 'tomorrow' then 1.day.from_now.midnight
    when 'this_week' then Date.today.beginning_of_week.midnight
    when 'next_week' then 1.week.from_now.beginning_of_week.midnight
    when 'later' then 1.month.from_now.midnight
    end
  end
end

project = $omnifocus.flattened_projects["Highrise"].get

Highrise::Task.find(:all, :from => :completed).each do |t|
  next unless t.updated_at >= 1.day.ago
  task = project.tasks[its.name.contains(t.id)].first.get rescue nil

  if task && !task.completed.get
    puts 'Completing in OmniFocus: ' + t.name_with_id
    task.completed.set true
  end
end

Highrise::Task.find(:all).each do |t|
  task = project.tasks[its.name.contains(t.id)].first.get rescue nil

  if task
    if task.completed.get
      puts 'Completing in Highrise: ' + t.name_with_id
      t.complete!
    else
      update_if_changed task, :note, t.url
      update_if_changed task, :name, t.name_with_id
      update_if_changed task, :due_date, t.due_at
      update_if_changed task, :defer_date, t.start_date
    end
  else
    puts 'Adding: ' + t.name_with_id
    project.make :new => :task, :with_properties => {
      :name => t.name_with_id,
      :note => t.url,
      :due_date => t.due_at,
      :defer_date => t.start_date
    }
  end
end
