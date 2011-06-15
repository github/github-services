class Service::Jira < Service
  def receive_push
    payload['commits'].each do |commit|
      next if commit['message'] =~ /^x /

      comment_body = "#{commit['message']}\n#{commit['url']}"

      commit['message'].match(/\[#(.+)\]/)
      # Don't need to continue if we don't have a commit message containing JIRA markup
      next unless $1

      jira_markup = $1.split
      issue_id = jira_markup.shift

      changeset = { :comment => { :body => comment_body } }

      jira_markup.each do |entry|
        key, value = entry.split(':')

        if key =~ /(?i)status|(?i)transition/
          changeset.merge!(:transition => value.to_i)
        elsif key =~ /(?i)resolution/
          changeset.merge!(:fields => { :resolution => value.to_i })
        else
          changeset.merge!(:fields => { key.to_sym => "Resolved" })
        end
      end

      # Don't need to continue if we don't have a transition to perform
      next unless changeset.has_key?(:transition)

      begin
        # :(
        http.ssl[:verify] = false

        http.basic_auth data['username'], data['password']
        http.headers['Content-Type'] = 'application/json'
        res = http_post '%s/rest/api/%s/issue/%s/transitions' % [data['server_url'], data['api_version'], issue_id],
          changeset.to_json
      rescue URI::InvalidURIError
        raise_config_error "Invalid server_hostname: #{data['server_hostname']}"
      end
    end
  end
end
