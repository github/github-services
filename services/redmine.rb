class Service::Redmine < Service
  string :address, :project, :api_key
  boolean :fetch_commits
  boolean :update_redmine_issues_about_commits
  white_list :address, :project

  def receive_push

    if fetch_github_commits_enabled?
      http.ssl[:verify] = false
      http.url_prefix = data['address']
      http_get "sys/fetch_changesets" do |req|
        req.params['key'] = data['api_key']
        req.params['id']  = data['project']
      end
    end

    if update_issues_enabled?
      begin
        # check configurations first
        check_configuration_options(data)

        payload['commits'].each do |commit|
          message = commit['message'].clone

          #Extract issue IDs and send update to the related issues
          while !(id= message[/#(\d)+/]).nil? do 
            message.gsub!(id,'')
            issue_no = id.gsub('#','')

            # Send the commit information to the related issue on redmine
            res = http_method :put, "#{data['address']}/issues/#{issue_no}.json" do |req|
              req.headers['Content-Type'] = 'application/json'
              req.headers['X-Redmine-API-Key'] = data['api_key']
              req.params['issue[notes]'] = commit_text(commit)
            end
          end
        end
        return true   
      rescue SocketError => se
        puts "SocketError has occured: #{se.inspect}"
        return false
      rescue Exception => e
        puts "Other Exception has occured: #{e.inspect}"
        return false
      end
    end
  end

  private
  def check_configuration_options(data)
    raise_config_error 'Redmine url must be set' if data['address'].blank?
    raise_config_error 'API key is required' if data['api_key'].blank?   
  end

  def fetch_github_commits_enabled?
    data['fetch_commits']
  end

  def update_issues_enabled?
    data['update_redmine_issues_about_commits']
  end

  #Extract and buffer the needed commit information into one string
  def commit_text(commit) 
    gitsha   = commit['id']
    added    = commit['added'].map    { |f| ['A', f] }
    removed  = commit['removed'].map  { |f| ['R', f] }
    modified = commit['modified'].map { |f| ['M', f] }

    timestamp = Date.parse(commit['timestamp'])

    commit_author = "#{commit['author']['name']} <#{commit['author']['email']}>"

    text = align(<<-EOH)
      Commit: #{gitsha}
          #{commit['url']}
      Author: #{commit_author}
      Date:   #{timestamp} (#{timestamp.strftime('%a, %d %b %Y')})

    EOH

    text << align(<<-EOH)
      Log Message:
      -----------
      #{commit['message']}
    EOH

    text
  end

  def align(text, indent = '  ')
    margin = text[/\A\s+/].size
    text.gsub(/^\s{#{margin}}/, indent)
  end

end
