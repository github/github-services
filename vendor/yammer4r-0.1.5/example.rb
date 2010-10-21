require 'yammer4r'

config_path = File.dirname(__FILE__) + 'oauth.yml'
yammer = Yammer::Client.new(:config => config_path)

# Get all messages
messages = yammer.messages
puts messages.size
puts messages.last.body.plain
puts messages.last.body.parsed

# Print out all the users
yammer.users.each do |u|
  puts "#{u.name} - #{u.me?}"
end
