class Service::ShiningPanda < Service
  string :workspace, :job, :token, :parameters

  def receive_push
    if workspace.empty?
      raise_config_error 'Workspace not set'
    end
    if job.empty?
      raise_config_error "Job not set"
    end
    if token.empty?
      raise_config_error "Token not set"
    end
    if query.has_key?('token')
      raise_config_error "Illegal parameter: token"
    end
    if query.has_key?('cause')
      raise_config_error "Illegal parameter: cause"
    end
    Rack::Utils.parse_query(data['parameters']).each do |key, values|
      if !values.is_a?(String) and values.length > 1
        raise_config_error "Only one parameter value allowed for " + key
      end
    end
    query[:token] = token
    query[:cause] = "Triggered by a push of #{payload['pusher']['name']} (commit: #{payload['after']})"
    http_post url, query
  end

  def cleanup(key)
    ( data.has_key?(key) and data[key] != nil ) ? data[key] : ''
  end
  
  def workspace
    @workspace ||= cleanup('workspace').strip
  end
    
  def job
    @job ||= cleanup('job').strip
  end

  def token
    @token ||= cleanup('token').strip
  end
  
  def parameters
    @parameters ||= Rack::Utils.parse_nested_query(cleanup('parameters'))
  end
  
  def query
    @query ||= parameters.clone
  end
  
  def url
    @url ||= "https://jenkins.shiningpanda.com/#{workspace}/job/#{job}/#{parameters.empty? ? 'build' : 'buildWithParameters'}"
  end
  
end