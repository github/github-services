class Service::AppHarbor < Service
  string :application_slug
  password :token
  white_list :application_slug

  def receive_push
    slugs = data['application_slug']
    token = data['token']

    raise_config_error 'Missing application slug' if slugs.to_s.empty?
    raise_config_error 'Missing token' if token.to_s.empty?

    slugs.split(",").each do |slug|
      slug.strip!
      post_appharbor_message(slug, token)
    end
  end

private

  def post_appharbor_message(slug, token)
    return unless commit = distinct_commits.last
    create_build_url = "https://appharbor.com/applications/#{slug}/builds"

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

    http_post create_build_url, generate_json(appharbor_message)
  end
end
