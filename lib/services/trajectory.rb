class Service::Trajectory < Service
  string :api_key
  BASE_URL = "https://www.apptrajectory.com/api/payloads?api_key="

  def receive_push
    send_to_trajectory
  end

  def receive_pull_request
    send_to_trajectory
  end

  private

  def send_to_trajectory
    set_http_headers
    response = send_post
    raise_config_error_for_bad_status(response)
  end

  def set_http_headers
    http.headers['content-type'] = 'application/json'
  end

  def send_post
    http_post full_url, json_payload
  end

  def full_url
    BASE_URL + api_key
  end

  def raise_config_error_for_bad_status(response)
    if response.status < 200 || response.status > 299
      raise_config_error
    end
  end

  def api_key
    raise_config_error "Missing 'api_key'" if data['api_key'].to_s == ''
    data['api_key'].to_s
  end

  def json_payload
    generate_json(payload)
  end
end
