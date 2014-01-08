class Service::RobusTest < Service
  default_events :issues, :issue_comment, :push
  string :project_key
  white_list :project_key

  url "http://www.robustest.com"
  logo_url "http://www.robustest.com/img/logo.png"
  maintained_by :github => 'omnarayan'
  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://robustest.com/',
    :email => 'care@robustest.com'
  
  def receive_push
    payload['commits'].each do |commit|
      next if commit['message'] =~ /^x /

      comment_body = "#{commit['message']}\n#{commit['url']}"

      commit['message'].match(/\[#(.+)\]/)
      # Don't need to continue if we don't have a commit message containing robustest markup
      next unless $1

      robustest_markup = $1.split
      issue_id = robustest_markup.shift

      changeset = { :comment => { :body => comment_body } }

      robustest_markup.each do |entry|
        key, value = entry.split(':')

        if key =~ /(?i)status|(?i)transition/
          changeset.merge!(:transition => value.to_s)
        elsif key =~ /(?i)resolution/
          changeset.merge!(:fields => { :resolution => { :id => value.to_s } })
        else
          changeset.merge!(:fields => { key.to_sym => "Resolved" })
        end
      end

      # Don't need to continue if we don't have a transition to perform
      next unless changeset.has_key?(:transition)

      begin
        http.headers['Content-Type'] = 'application/json'
        res = http_post 'http://www.robustest.com/project/%s/integration/git/%s' % [data['project_key'],  issue_id],
          generate_json(changeset)
      rescue URI::InvalidURIError
        raise_config_error "Invalid project: #{data['project_key']}"
      end
    end
  end
end
