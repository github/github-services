# Inspired by: http://github.com/adamhjk/github-commit-email/tree
service :email do |data, payload|
  
  body = <<-EOH
Commits to #{payload['repository']['name']} (#{payload['repository']['url']})
Ref: #{payload['ref']} 

EOH
  payload['commits'].each do |gitsha, commit|
  body << <<-EOH
#{gitsha} by #{commit['author']['name']} (#{commit['author']['email']}) @ #{commit['timestamp']}
#{commit['url']}

#{commit['message']}

EOH
  end
  
  message = TMail::Mail.new
  message.set_content_type("text", "plain")
  message.subject = "GitHub commit notice for #{payload['repository']['owner']['name']}-#{payload['repository']['name']}"
  message.date = Time.now
  message.body = body
  
  Net::SMTP.start('localhost', 25) do |smtp|
    smtp.send_message message.to_s, "#{payload['repository']['owner']['name']}-#{payload['repository']['name']}@github.com", data['address']
  end
end