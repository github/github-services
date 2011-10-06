class Service::Basecamp < Service
  string   :url, :project, :category, :username
  password :password
  boolean  :ssl

  def receive_push
    repository      = payload['repository']['name']
    name_with_owner = File.join(payload['repository']['owner']['name'], repository)
    branch          = payload['ref_name']

    commits = payload['commits'].reject { |commit| commit['message'].to_s.strip == '' }
    return if commits.empty?

    ::Basecamp.establish_connection! basecamp_domain,
      data['username'], data['password'], data['ssl'].to_i == 1

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

      post_message :title => title, :body => body
    end

  rescue SocketError => boom
    if boom.to_s =~ /getaddrinfo: Name or service not known/
      raise_config_error "Invalid basecamp domain name"
    else
      raise
    end
  rescue ActiveResource::ForbiddenAccess => boom
    raise_config_error boom.to_s
  rescue RuntimeError => boom
    if boom.to_s =~ /\((?:403|401|422)\)/
      raise_config_error "Invalid credentials: #{boom}"
    elsif boom.to_s =~ /\((?:404|301)\)/
      raise_config_error "Invalid project URL: #{boom}"
    elsif boom.to_s == 'Unprocessable Entity (422)'
      # do nothing
    else
      raise
    end
  end

  attr_writer :basecamp
  attr_writer :project_id
  attr_writer :category_id

  def basecamp_domain
    @basecamp_domain ||= Addressable::URI.parse(data['url']).host
  end

  def build_message(options = {})
    m = ::Basecamp::Message.new :project_id => project_id
    m.category_id = category_id
    options.each do |key, value|
      m.send "#{key}=", value
    end
    m
  end

  def post_message(options = {})
    build_message(options).save
  end

  def project_id
    @project_id ||= begin
      name = data['project'].to_s
      name.downcase!
      if proj = ::Basecamp::Project.all.detect { |p| p.name.downcase == name }
        proj.id
      else
        raise_config_error("Invalid Project: #{name.downcase}")
      end
    end
  end

  def category_id
    @category_id ||= begin
      name = data['category'].to_s
      name.downcase!
      if cat = ::Basecamp::Category.post_categories(project_id).detect { |c| c.name.downcase == name }
        cat.id
      else
        raise_config_error("Invalid Category: #{data['category'].inspect}")
      end
    end
  end
end
