# https://trello.com/1/appKey/generate#
# https://trello.com/1/authorize?key=865622db0ef822fbdbef22bffa1235a7&expiration=never&name=Services+to+
# OmniFocus&response_type=token&scope=read,write
require "trello"

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

Trello::Member.find('my').cards.each do |card|
  project_name = card.board.name
  project = $omnifocus.flattened_projects[project_name].get
  task_id = "[#%d]" % card.short_id
  task = project.tasks[its.name.contains(task_id)].first.get rescue nil

  if task
    if task.completed.get && card.list.name.downcase != 'done'
      puts 'Completing in Trello: ' + task_id
      done_list = card.board.lists.detect { |l| l.name.downcase == 'done' }
      card.move_to_list(done_list)
    elsif card.list.name.downcase == 'done'
      puts 'Completing in OmniFocus: ' + task_id
      task.completed.set true
    else
      update_if_changed task, :note, card.url
      update_if_changed task, :name, "%s %s" % [card.name, task_id]
    end
  elsif card.list.name.downcase != 'done'
    puts 'Adding: ' + task_id
    project.make :new => :task, :with_properties => {
      :name => "%s %s" % [card.name, task_id],
      :note => card.url,
    }
  end

end
