require "rubygems"
require "bundler/setup"
require "appscript"
require "optparse"

def its
  Appscript.its
end

def update_if_changed(task, field, value)
  if task.send(field).get != value
    puts "Updating field #{field} of task #{task.name.get}"
    task.send(field).set value
  end
end

$options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: services-to-omnifocus.rb [options]"
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
  opts.on('-v', '--verbose', 'Run verbosely') do |v|
    $options[:verbose] = v
  end
end.parse!

plugin_dir = File.join(File.dirname(File.expand_path(__FILE__)), 'plugins')
Dir.glob(File.join(plugin_dir, '*.rb')).each do |plugin|
  puts 'Processing "%s" plugin' % File.basename(plugin, '.rb') if $options[:verbose]
  require plugin
end
