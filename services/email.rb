email_conf = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'config', 'email.yml'))

service :email do |data, payload|
  name_with_owner = File.join(payload['repository']['owner']['name'], payload['repository']['name'])

  # Should be: first_commit = payload['commits'].first
  first_commit     = payload['commits'].first
  next if first_commit.nil?

  first_commit_sha = first_commit['id']

  # Shorten the elements of the subject
  first_commit_sha = first_commit_sha[0..5]

  first_commit_title = first_commit['message'][/^([^\n]+)/, 1]
  if first_commit_title.length > 50
    first_commit_title = first_commit_title.slice(0,50) << '...'
  end

  body = <<-EOH
Branch: #{payload['ref']}
Home:   #{payload['repository']['url']}

EOH

  payload['commits'].each do |commit|
    gitsha   = commit['id']
    added    = commit['added'].map    { |f| ['A', f] }
    removed  = commit['removed'].map  { |f| ['R', f] }
    modified = commit['modified'].map { |f| ['M', f] }

    changed_paths = (added + removed + modified).sort_by { |(char, file)| file }
    changed_paths = changed_paths.collect { |entry| entry * ' ' }.join("\n  ")

    timestamp = Date.parse(commit['timestamp'])

    body << <<-EOH
Commit: #{gitsha}
    #{commit['url']}
Author: #{commit['author']['name']} <#{commit['author']['email']}>
Date:   #{timestamp} (#{timestamp.strftime('%a, %d %b %Y')})

EOH

    if changed_paths.size > 0
      body << <<-EOH
Changed paths:
  #{changed_paths}

EOH
    end

    body << <<-EOH
Log Message:
-----------
#{commit['message']}


EOH
  end

  message = TMail::Mail.new
  message.set_content_type('text', 'plain', {:charset => 'UTF-8'})
  message.to      = data['address']
  message.subject = "[#{name_with_owner}] #{first_commit_sha}: #{first_commit_title}"
  message.body    = body
  message.date    = Time.now

  smtp_settings  = [ email_conf['address'], (email_conf['port'] || 25).to_i, (email_conf['domain'] || 'localhost.localdomain') ]
  smtp_settings += [ email_conf['user_name'], email_conf['password'], email_conf['authentication'] ] if email_conf['authentication']

  Net::SMTP.start(*smtp_settings) do |smtp|
    smtp.send_message message.to_s, "GitHub <noreply@github.com>", data['address']
  end
end
