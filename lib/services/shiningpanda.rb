class Service::ShiningPanda < Service
  string :workspace, :job, :token, :branches, :parameters
  white_list :workspace, :job, :branches, :parameters

  def receive_push
    http.ssl[:verify] = false # :(
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
    branch = payload['ref'].to_s.split('/').last
    if branches.empty? || branches.include?(branch)
      Faraday::Utils.parse_query(data['parameters']).each do |key, values|
        if !values.is_a?(String) and values.length > 1
          raise_config_error "Only one parameter value allowed for " + key
        end
      end
      query[:token] = token
      query[:cause] = "Triggered by a push of #{payload['pusher']['name']} to #{branch} (commit: #{payload['after']})"
      http_post url, query
    end
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

  def branches
    @branches ||= cleanup('branches').strip.split(/\s+/)
  end

  def parameters
    @parameters ||= Faraday::Utils.parse_nested_query(cleanup('parameters'))
  end

  def query
    @query ||= parameters.clone
  end

  def url
    @url ||= "https://jenkins.shiningpanda-ci.com/#{workspace}/job/#{job}/#{parameters.empty? ? 'build' : 'buildWithParameters'}"
  end
end
