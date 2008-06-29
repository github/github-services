service :email do |data, payload|

  name_with_owner = File.join(payload['repository']['owner']['name'], payload['repository']['name'])
  
  body = <<-EOH
Commits to #{name_with_owner}
Ref:  #{payload['ref']}
Home: #{payload['repository']['url']}


EOH

  payload['commits'].each do |gitsha, commit|
    body << <<-EOH
#{commit['timestamp']} - #{commit['author']['name']} (#{commit['author']['email']})
#{commit['url']}

#{commit['message']}


EOH
  end
  
  message = TMail::Mail.new
  message.set_content_type('text', 'plain')
  message.subject = "[GitHub] Push: #{name_with_owner} - #{payload['ref'].split('/').last}"
  message.body    = body
  message.date    = Time.now
  
  Net::SMTP.start('smtp', 25, 'github.com') do |smtp|
    smtp.send_message message.to_s, 'noreply@github.com', data['address']
  end
end
