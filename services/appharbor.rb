class Service::AppHarbor < Service
  string :application_slug, :token
  
  def receive_push
    slug = data['application_slug']
    token = data['token']

    raise_config_error 'Missing application slug' if slug.to_s.empty?
    raise_config_error 'Missing token' if token.to_s.empty?

    create_build_url = "https://appharbor.com/applications/#{slug}/builds"

    commit = distinct_commits.last
    appharbor_message = {
      :branches => {
        ref_name => {
          :commit_id => commit['id'],
          :commit_message => commit['message'],
          :download_url => commit['url'].sub('commit', 'tarball')
        }
      }
    }

    http.headers['Accept'] = 'application/json'
    http.headers['Authorization'] = "BEARER #{token}"

    http_post create_build_url, appharbor_message.to_json
  end
end
