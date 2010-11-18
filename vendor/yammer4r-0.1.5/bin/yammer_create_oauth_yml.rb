#!/usr/bin/env ruby

# Instructions:
#
# Register your application at https://www.yammer.com/client_applications/new
# Upon successful registration, you'll recieve your consumer key and secret.
# Pass these values on the command line as --key (-k) and --secret (-s) then
# follow the instructions.

require 'optparse'
require 'rubygems'
require 'oauth'

OPTIONS = {
  :outfile  => 'oauth.yml'
}

YAMMER_OAUTH = "https://www.yammer.com" 

ARGV.options do |o|
  script_name = File.basename($0)
  
  o.set_summary_indent('  ')
  o.banner =    "Usage: #{script_name} [OPTIONS]"
  o.define_head "Create a yaml file for yammer oauth"
  o.separator   ""
  o.separator   "[-k] and [-s] options are mandatory"
  o.separator   ""
  
  o.on("-o", "--outfile=[val]", String,
       "Yaml output file",
       "Default: #{OPTIONS[:outfile]}")     { |OPTIONS[:outfile]| }
  o.on("-k", "--key=val", String,
       "Consumer key for Yammer app")       { |key| OPTIONS[:key] = key}
  o.on("-s", "--secret=val", String,
       "Consumer secret for Yammer app")    { |secret| OPTIONS[:secret] = secret}
  
  o.separator ""

  o.on_tail("-h", "--help", "Show this help message.") { puts o; exit }
  o.parse!
end

unless OPTIONS[:key] && OPTIONS[:secret]
  raise ArgumentError, "Must supply consumer key and secret (use -h for help)"
end

consumer      = OAuth::Consumer.new OPTIONS[:key], OPTIONS[:secret], {:site => YAMMER_OAUTH}
request_token = consumer.get_request_token

puts "Please visit the following URL in your browser to authorize your application, then enter the 4 character security code when done: #{request_token.authorize_url}"
oauth_verifier =  gets
response = consumer.token_request(consumer.http_method, 
                                  (consumer.access_token_url? ? consumer.access_token_url : consumer.access_token_path),
                                  request_token, 
                                  {}, 
                                  :oauth_verifier =>  oauth_verifier.chomp)
access_token = OAuth::AccessToken.new(consumer,response[:oauth_token],response[:oauth_token_secret])

oauth_yml = <<-EOT
consumer:
  key: #{OPTIONS[:key]}
  secret: #{OPTIONS[:secret]}
access:
  token: #{access_token.token}
  secret: #{access_token.secret}
EOT

File.open(OPTIONS[:outfile], "w") do |f|
  f.write oauth_yml
end
