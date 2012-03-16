class Service::AgileBench < Service
  string :token, :project_id

  def receive_push
    token, project_id =
     data['token'].to_s.strip, data['project_id'].to_s.strip

    raise_config_error "Invalid Token" if !token.present?
    raise_config_error "Invalid Project ID" if !project_id.present?

    response = {:token => token,
                :project_id => project_id}

    if payload["commits"]
      response.merge!({ :commit => {
                          :message => payload['commits'].last["message"]
                        },
                        :github_user => {
                          :username => payload['commits'].last["committer"]["username"],
                          :email => payload['commits'].last["committer"]["email"]
                        }
      })
    end

    http_post "http://93.181.168.171:9393/",
      {:data => response.to_json}
  end
end

