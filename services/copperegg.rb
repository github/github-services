class Service::CopperEgg < Service
  string   :tag
  boolean  :master_only
  password :api_key

  def receive_push
    raise_config_error 'API Key must be set' if data['api_key'].blank?

    if data['master_only'].to_i == 1 && branch_name != 'master'
      return
    end

    note = "GitHub: #{payload['pusher']['name']} has pushed #{payload['commits'].size} commit(s) to #{payload['repository']['name']}"
    
    res = http_post "https://#{api_key}:U@api.copperegg.com/v2/annotations.json",
      :note => note,
      :starttime => Time.now.to_i - 30,
      :endtime => Time.now.to_i + 30,
      :tags => tag
    if res.status < 200 || res.status > 299
      raise_config_error
    end
  end
end
