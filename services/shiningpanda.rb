class Service::ShiningPanda < Service
  string :workspace, :job, :token, :parameters

  def receive_push
    if data['workspace'].to_s.empty?
      raise_config_error "Workspace not set"
    end
    if data['job'].to_s.empty?
      raise_config_error "Job not set"
    end
    if data['token'].to_s.empty?
      raise_config_error "Token not set"
    end
    http.ssl[:verify] = true
    http_post url, \
      :from => 'github', \
      :token => data['token'].strip, \
      :payload => payload.to_json
  end
  
  def url
    "https://jenkins.shiningpanda.com/#{data['workspace'].strip}/job/#{data['job'].strip}/" \
      + ( data['parameters'].to_s.empty? ? "build" : "buildWithParameters?#{data['parameters']}" )
  end
  
end