require "rubygems"
require "bundler/setup"
require "zendesk_api"
require "highrise"
require "appscript"

Highrise::Base.site = ENV['HIGHRISE_HOST']
Highrise::Base.user = ENV['HIGHRISE_USER']
Highrise::Base.format = :xml

ZENDESK_VIEW_ID = ENV['ZENDESK_VIEW']
ZENDESK_BASE_URI = ENV['ZENDESK_URL']

@zendesk = ZendeskAPI::Client.new do |config|
  config.url = File.join(ENV['ZENDESK_URL'], '/api/v2')
  config.username = ENV['ZENDESK_USER']
  config.password = ENV['ZENDESK_PASS']
end

def its
  Appscript.its
end

def update_if_changed(task, field, value)
  if task.send(field).get != value
    puts "Updating field #{field} of task #{task.name.get}"
    task.send(field).set value
  end
end
