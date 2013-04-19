class Service::CopperEgg < Service
  string   :url, :tag
  boolean  :master_only
  string   :api_key

  def receive_push

    raise_config_error 'API Key must be set' if data['api_key'].blank?

    if data['master_only'].to_i == 1 && branch_name != 'master'
      return
    end

    http.ssl[:verify] = false
    http.basic_auth(data['api_key'], "U")
    http.headers['Content-Type'] = 'application/json'
    if data['url'] != "" && data['url'] != nil
      url = data['url']
    else
      url = "https://api.copperegg.com/v2/annotations.json"
    end
    note = "GitHub: #{payload['pusher']['name']} has pushed #{payload['commits'].size} commit(s) to #{payload['repository']['name']}"
    body = {"note" => note, "starttime" => Time.now.to_i - 30, "endtime" => Time.now.to_i + 30, "tags" => data['tag']}
    json = generate_json(body)

    res = http_post url, json
    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
