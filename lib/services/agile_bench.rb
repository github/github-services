class Service::AgileBench < Service
  password :token
  string :project_id
  white_list :project_id

  def receive_push
    ensure_required_data
    post_to_agile_bench
    verify_response
  end

  protected
  def ensure_required_data
    raise_config_error "Token is required"      if !token.present?
    raise_config_error "Project ID is required" if !project_id.present?
  end

  def post_to_agile_bench
    @response = http_post "http://agilebench.com/services/v1/github" do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = generate_json({
        :payload => payload,
        :data => {
          :project_id => project_id,
          :token => token
        }
      })
    end
  end

  def token
    @token ||= data['token'].to_s.strip
  end

  def project_id
    @project_id ||= data['project_id'].to_s.strip
  end

  def verify_response
    case @response.status
      when 200..299
      when 403, 401, 422 then raise_config_error("Invalid Credentials")
      when 404, 301, 302 then raise_config_error("Invalid URL")
      else raise_config_error("HTTP: #{@response.status}")
    end
  end
end

