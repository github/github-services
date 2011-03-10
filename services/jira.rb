require 'json'

service :jira do |data, payload|
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
      url = URI.parse('%s/rest/api/%s/issue/%s/transitions' % [data['server_url'], data['api_version'], issue_id])
      Net::HTTP.start(url.host, url.port) do |http|
        req = Net::HTTP::Post.new(url.path)
        req.basic_auth data['username'], data['password']
        req.body = changeset.to_json
        req.set_content_type('application/json')
        response = http.request(req)
        puts response.body
      end
    rescue URI::InvalidURIError
      raise GitHub::ServiceConfigurationError, "Invalid server_hostname: #{data['server_hostname']}"
    end
  end
end
