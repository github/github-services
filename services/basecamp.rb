service :basecamp do |data, payload|
  begin
    repository      = payload['repository']['name']
    name_with_owner = File.join(payload['repository']['owner']['name'], repository)
    branch          = payload['ref_name']

    basecamp    = Basecamp.new(data['url'], data['username'], data['password'])
    project_id  = basecamp.projects.select { |p| p.name.downcase == data['project'].downcase }.first.id
    category_id = basecamp.message_categories(project_id).select { |category| category.name.downcase == data['category'].downcase }.first.id

    commits = payload['commits'].reject { |commit| commit['message'].to_s.strip == '' }
    next if commits.empty?

    commits.each do |commit|
      gitsha        = commit['id']
      short_git_sha = gitsha[0..5]
      timestamp     = Date.parse(commit['timestamp'])

      added         = commit['added'].map    { |f| ['A', f] }
      removed       = commit['removed'].map  { |f| ['R', f] }
      modified      = commit['modified'].map { |f| ['M', f] }
      changed_paths = (added + removed + modified).sort_by { |(char, file)| file }
      changed_paths = changed_paths.collect { |entry| entry * ' ' }.join("\n  ")

      # Shorten the elements of the subject
      commit_title = commit['message'][/^([^\n]+)/, 1]
      if commit_title.length > 50
        commit_title = commit_title.slice(0,50) << '...'
      end

      title = "Commit on #{name_with_owner}: #{short_git_sha}: #{commit_title}"

      body = <<-EOH
*Author:* #{commit['author']['name']} <#{commit['author']['email']}>
*Commit:* <a href="#{commit['url']}">#{gitsha}</a>
*Date:*   #{timestamp} (#{timestamp.strftime('%a, %d %b %Y')})
*Branch:* #{branch}
*Home:*   #{payload['repository']['url']}

h2. Log Message

<pre>#{commit['message']}</pre>
EOH

      if changed_paths.size > 0
        body << <<-EOH

h2. Changed paths

<pre>  #{changed_paths}</pre>
EOH
      end

      basecamp.post_message(project_id, :title => title, :body => body, :category_id => category_id)
    end

  rescue SocketError => boom
    if boom.to_s =~ /getaddrinfo: Name or service not known/
      raise GitHub::ServiceConfigurationError, "Invalid basecamp domain name"
    else
      raise
    end
  rescue RuntimeError => boom
    if boom.to_s =~ /\((?:403|401|422)\)/
      raise GitHub::ServiceConfigurationError, "Invalid credentials"
    elsif boom.to_s == 'Not Found (404)'
      raise GitHub::ServiceConfigurationError, "Invalid project URL"
    elsif boom.to_s == 'Unprocessable Entity (422)'
      # do nothing
    else
      raise
    end
  end
end
