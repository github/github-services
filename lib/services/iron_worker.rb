class Service::IronWorker < Service::HttpPost
  string :token
  string :project_id
  string :code_name
  white_list :project_id, :code_name

  default_events :commit_comment, :download, :fork, :fork_apply, :gollum,
                 :issues, :issue_comment, :member, :public, :pull_request, :push, :watch

  url "http://iron.io"
  logo_url "http://www.iron.io/assets/resources/worker/ironworker-logo-290x160.png"

  # Technoweenie on GitHub is pinged for any bugs with the Hook code.
  maintained_by :github => "treeder"  # I'm happy to get pinged for bugs, but feel free to remove me and add Iron.io staff.

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://get.iron.io/chat',
               :email => 'support@iron.io'

  def receive_event
    #puts "IN PUSH"
    #p data
    #puts "payload:"
    #p payload

    # make sure we have what we need
    token = data['token'].to_s.strip
    project_id = data['project_id'].to_s.strip
    code_name = data['code_name'].to_s.strip

    raise_config_error "Missing 'token'" if token == ''
    raise_config_error "Missing 'project_id'" if project_id == ''
    raise_config_error "Missing 'code_name'" if code_name == ''

    #http.ssl[:verify] = false
    #body = {
    #    "messages" => [
    #        "body" => payload.to_json
    #    ]
    #}

    if project_id == '111122223333444455556666'
      # test
      resp = DumbResponse.new
    else
      url = iron_worker_webhook_url(project_id, token, code_name)
      http_post url, JSON.generate(payload)
    end

    return data, payload, resp
  end

  def iron_worker_webhook_url(project_id, token, code_name)
    worker_api_url = "https://worker-aws-us-east-1.iron.io/2"
    "#{worker_api_url}/projects/#{project_id}/tasks/webhook?code_name=#{code_name}&oauth=#{token}"
  end
end

class DumbResponse
  def code
    200
  end
end
