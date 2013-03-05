#!/usr/bin/ruby
require "config"

omnifocus = Appscript.app('OmniFocus').default_document
project = omnifocus.flattened_projects["Zendesk"].get

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
        task.context.set omnifocus.flattened_contexts["Online"]
      end
    when 'Solved' then
      unless task.completed.get
        puts "Completing Ticket ##{row.ticket.id} in OmniFocus"
        task.completed.set true
      end
    when 'Pending', 'On-hold' then
      unless task.context.name.get == 'Waiting For'
        puts "Marking Ticket ##{row.ticket.id} as Waiting For"
        task.context.set omnifocus.flattened_contexts["Waiting For"]
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
