class Service::IronMQ < Service
  password :token
  string :project_id
  string :queue_name
  white_list :project_id, :queue_name

  default_events :commit_comment, :download, :fork, :fork_apply, :gollum,
                 :issues, :issue_comment, :member, :public, :pull_request, :push, :watch

  url "http://iron.io"
  logo_url "http://www.iron.io/assets/resources/mq/ironmq-logo-290x160.png"

  # Technoweenie on GitHub is pinged for any bugs with the Hook code.
  maintained_by :github => 'treeder'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://support.iron.io',
               :email => 'support@iron.io'

  def receive_event
    #puts "IN PUSH"
    #p data
    #puts "payload:"
    #p payload

    # make sure we have what we need
    token = data['token'].to_s.strip
    project_id = data['project_id'].to_s.strip
    queue_name = data['queue_name'].to_s.strip
    raise_config_error "Missing 'token'" if token == ''
    raise_config_error "Missing 'project_id'" if project_id == ''
    queue_name = queue_name != '' ? queue_name : "github_service_hooks"

    #http.ssl[:verify] = false
    body = {
        "messages" => [
            "body" => generate_json(payload)
        ]
    }

    if project_id == '111122223333444455556666'
      # test
      resp = DumbResponse.new
    else
      http_post " https://mq-aws-us-east-1.iron.io/1/projects/#{project_id}/queues/#{queue_name}/messages", generate_json(body), {"Authorization" => "OAuth #{token}"}
    end

    return data, payload, resp

  end
end

class DumbResponse
  def code
    200
  end
end
