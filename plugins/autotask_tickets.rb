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

AUTOTASK_RESOLVED = ENV['AUTOTASK_RESOLVED']
AUTOTASK_WAITING = ENV['AUTOTASK_WAITING'].split(/,\s*/)
AUTOTASK_CONTEXT = ENV['AUTOTASK_CONTEXT']
AUTOTASK_REGION = ENV['AUTOTASK_WSDL'].match(/webservices(\d)/)[1]

@client = AutotaskAPI::Client.new do |client|
    client.basic_auth = [
      ENV['AUTOTASK_USER'],
      ENV['AUTOTASK_PASS'],
    ]
    client.wsdl = ENV['AUTOTASK_WSDL']
end

@my_user = AutotaskAPI::Resource.find_by_email ENV['AUTOTASK_USER']

@query = AutotaskAPI::QueryXML.new do |query|
  query.entity = 'ticket'
end
@query.add_condition 'CreateDate', 'GreaterThan', 3.months.ago.to_s
@query.add_condition 'AssignedResourceID', 'Equals', @my_user.id

project = $omnifocus.flattened_projects["Autotask"].get

def ticket_name(ticket)
  account = AutotaskAPI::Account.find ticket.account_id
  "#{ticket.ticket_number}: #{ticket.title} (#{account.account_name})"
end

@client.entities_for(@query).each do |ticket|
  task = project.tasks[its.name.contains(ticket.ticket_number)].first.get rescue nil

  if task
    case ticket.status
    when AUTOTASK_RESOLVED then
      unless task.completed.get
        puts "Completing Ticket #{ticket.ticket_number} in OmniFocus"
        task.completed.set true
      end
    when *AUTOTASK_WAITING then
      unless task.context.name.get == 'Waiting'
        puts "Marking Ticket #{ticket.ticket_number} as Waiting"
        task.context.set $omnifocus.flattened_contexts["Waiting"]
        task.flagged.set false
      end
    else
      if task.context && task.context.name.get == 'Waiting'
        puts "Marking Ticket #{ticket.ticket_number} as in progress"
        task.context.set $omnifocus.flattened_contexts[AUTOTASK_CONTEXT]
        task.flagged.set true
      end
    end
  else
    puts "Adding Ticket #{ticket.ticket_number}"
    project.make :new => :task, :with_properties => {
      :name => ticket_name(ticket),
      :flagged => true,
      :note => "https://ww#{AUTOTASK_REGION}.autotask.net/Autotask/AutotaskExtend/ExecuteCommand.aspx?Code=OpenTicketDetail&TicketNumber=#{ticket.ticket_number}"
    }
  end
end
