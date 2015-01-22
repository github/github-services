class Service::JIRA < Service
  string   :server_url, :api_version, :username
  password :password
  boolean :post_comments
  white_list :api_version, :server_url, :username, :post_comments

  def receive_push
    payload['commits'].each do |commit|
      next if commit['message'] =~ /^x /

      author_display = "#{commit['author']['name']} <#{commit['author']['email']}>"
      comment_body = "#{commit['message']}\n#{commit['url']}"
      files_changed = "\n"

      # list each updated file's status in this commit
      if config_boolean_true?('post_comments')
        status_idx = [['A','added'],['D','removed'],['M','modified']]

        # store in files_changed for post
        status_idx.each do |abbr,file_st|
          commit["#{file_st}"].each do |file|
            files_changed.concat("#{abbr}\t#{file}\n")
          end
        end
      end #if

      commit['message'].match(/\[#(.+)\]/)
      # Don't need to continue if we don't have a commit message containing JIRA markup
      next unless $1

      jira_markup = $1.split
      issue_id = jira_markup.shift

      changeset = { :comment => { :body => comment_body } }

      jira_markup.each do |entry|
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
      next unless (changeset.has_key?(:transition) or config_boolean_true?('post_comments'))

      begin
        # :(
        http.ssl[:verify] = false

        http.basic_auth data['username'], data['password']
        http.headers['Content-Type'] = 'application/json'
        if changeset.has_key?(:transition)
            res = http_post '%s/rest/api/%s/issue/%s/transitions' % [data['server_url'], data['api_version'], issue_id],
              generate_json(changeset)
        end

        # add a comment containing the author, msg, and files changed
        if config_boolean_true?('post_comments')
              res = http_post '%s/rest/api/%s/issue/%s/comment' % [data['server_url'], data['api_version'], issue_id],
              generate_json({ :body => "#{author_display}\n\n#{comment_body}\n\n#{files_changed}"})
        end
      rescue URI::InvalidURIError
        raise_config_error "Invalid server_hostname: #{data['server_url']}"
      end
    end
  end
end
