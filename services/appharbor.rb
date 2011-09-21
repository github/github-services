class Service::AppHarbor < Service
  string :create_build_url
  
  def receive_push
    raise_config_error 'Missing Create build URL' if data['create_build_url'].to_s.empty?

    commit = distinct_commits.last
    appharbor_message = {
      :branches => {
        ref_name => {
          :commit_id => commit["id"],
          :commit_message => commit["message"],
          :download_url => commit["url"].sub("commit", "tarball")
        }
      }
    }

    http_post(data["create_build_url"], appharbor_message.to_json, 'Accept' => 'application/json')
  end
end
