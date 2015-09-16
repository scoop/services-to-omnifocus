#
# Create OmniFocus tasks for tickets assigned to you in Autotask.
# When tickets change in Autotask, those changes are reflected in OmniFocus. Changes
# to tasks in OmniFocus are *not* synced back to Autotask at this point.
#
# Authentication data is taken from these environment variables:
#
#   AUTOTASK_WSDL: Contains the URL of the WSDL on the webservices host for your Autotask region
#   AUTOTASK_USER: Contains the username (typically an email address) of your Autotask user
#   AUTOTASK_PASS: Contains your Autotask password
#
# Additionally, the script needs the ID of the 'resolved' ticket status in Autotask
# in the variable AUTOTASK_RESOLVED. Usually this is the ID 5. Lastly,
# a comma-separated list of status IDs can be set in the variable
# AUTOTASK_WAITING, listing all the IDs that map to your "Waiting For" context
# in OmniFocus

require "autotask_api"

AUTOTASK_TODO_REGION = ENV['AUTOTASK_WSDL'].match(/webservices(\d)/)[1]
AUTOTASK_OFFSET = ENV['AUTOTASK_OFFSET'] || 6 * 3600

@client = AutotaskAPI::Client.new do |client|
    client.basic_auth = [
      ENV['AUTOTASK_USER'],
      ENV['AUTOTASK_PASS'],
    ]
    client.wsdl = ENV['AUTOTASK_WSDL']
end

@my_user = AutotaskAPI::Resource.find_by_email ENV['AUTOTASK_USER']

@query = AutotaskAPI::QueryXML.new do |query|
  query.entity = 'accounttodo'
end
@query.add_condition 'AssignedToResourceID', 'Equals', @my_user.id
@query.add_condition 'CreateDateTime', 'GreaterThan', 3.months.ago.to_s

project = $omnifocus.flattened_projects["Autotask"].get

def todo_name(todo)
  account = AutotaskAPI::Account.find todo.account_id
  "#{account.account_name}: #{todo.title} (##{todo.id})"
end

def todo_description(todo)
  "#{todo.description}\n\nhttps://ww#{AUTOTASK_TODO_REGION}.autotask.net/Autotask/AutotaskExtend/ExecuteCommand.aspx?Code=OpenAccount&AccountID=#{todo.account_id}"
end

def time_offset(time)
  time += AUTOTASK_OFFSET
  # time += 12 * 3600 if time.hour > 7
  time
end

@client.entities_for(@query).each do |todo|
  task = project.tasks[its.name.contains(todo.id)].first.get rescue nil

  if task
    unless todo.completed_date.blank?
      unless task.completed.get
        puts "Completing Todo #{todo.id} in OmniFocus"
        task.completed.set true
      end
    else
      update_if_changed task, :name, todo_name(todo)
      # update_if_changed task, :note, todo_description(todo)
      update_if_changed task, :defer_date, todo.start_time.to_date
      # update_if_changed task, :due_date, time_offset(todo.end_time)
    end
  else
    puts "Adding Todo #{todo.id}"
    project.make new: :task,
      with_properties: {
      name: todo_name(todo),
      note: todo_description(todo),
      defer_date: todo.start_time.to_date
    }
    # due_date: time_offset(todo.end_time)
  end
end
