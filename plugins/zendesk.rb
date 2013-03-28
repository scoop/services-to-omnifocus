#
# Create OmniFocus tasks for tickets assigned to you in Zendesk.
# When tickets change in Zendesk, those changes are reflected in OmniFocus. Changes
# to tasks in OmniFocus are *not* synced back to Zendesk at this point.
#
# Authentication data is taken from these environment variables:
#
#   ZENDESK_HOST: Contains the name of the virtual host of your Zendesk account
#   ZENDESK_USER: Contains the username (typically an email address) of your Zendesk user
#   ZENDESK_PASS: Contains your Zendesk password
#
# Additionally, the script needs the ID of a view in Zendesk that contains all of your tickets
# in every state (new, open, pending, on-hold, solved, closed) in the variable ZENDESK_VIEW.

require "zendesk_api"

ZENDESK_VIEW_ID = ENV['ZENDESK_VIEW']
ZENDESK_BASE_URI = ENV['ZENDESK_HOST']
ZENDESK_CONTEXT = ENV['ZENDESK_CONTEXT']

@zendesk = ZendeskAPI::Client.new do |config|
  config.url = File.join(ENV['ZENDESK_HOST'], '/api/v2')
  config.username = ENV['ZENDESK_USER']
  config.password = ENV['ZENDESK_PASS']
end

project = $omnifocus.flattened_projects["Zendesk"].get

def ticket_name(row)
  if row.organization_id
    organization = @zendesk.organization.find(:id => row.organization.id)
  end
  "##{row.ticket.id}: #{organization ? organization.name + ': ' : ''} #{row.subject}"
end

@zendesk.views.find(:id => ZENDESK_VIEW_ID).rows.each do |row|
  task = project.tasks[its.name.contains(row.ticket.id)].first.get rescue nil

  if task
    case row.status
    when 'Open' then
      if task.context && task.context.name.get == 'Waiting For'
        puts "Marking Ticket ##{row.ticket.id} as in progress"
        task.context.set $omnifocus.flattened_contexts[ZENDESK_CONTEXT]
      end
    when 'Solved' then
      unless task.completed.get
        puts "Completing Ticket ##{row.ticket.id} in OmniFocus"
        task.completed.set true
      end
    when 'Pending', 'On-hold' then
      unless task.context.name.get == 'Waiting For'
        puts "Marking Ticket ##{row.ticket.id} as Waiting For"
        task.context.set $omnifocus.flattened_contexts["Waiting For"]
      end
    end
  else
    puts "Adding Ticket ##{row.ticket.id}"
    project.make :new => :task, :with_properties => {
      :name => ticket_name(row),
      :note => ZENDESK_BASE_URI + '/tickets/' + row.ticket.id.to_s
    }
  end
end
