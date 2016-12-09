class Service::GoCD < Service
  string   :base_url, :repository_url, :username
  password :password
  boolean :verify_ssl
  white_list :base_url, :repository_url, :username

  url "http://www.go.cd/"
  logo_url "http://www.go.cd/images/logo-go-home_2014.png"
  maintained_by github: "manojlds"

  def receive_push
    return if payload['deleted']
    validate_config

    http.ssl[:verify] = verify_ssl
    http.url_prefix = base_url
    http.headers['confirm'] = true

    http.basic_auth username, password if username.present? and password.present?

    res = http_post "go/api/material/notify/git", repository_url: repository_url
    case res.status
      when 200..299
      when 403, 401, 422 then raise_config_error("Invalid credentials")
      when 404, 301, 302 then raise_config_error("Invalid Go server URL")
      else raise_config_error("HTTP: #{res.status}")
    end
  rescue SocketError => e
    raise_config_error "Invalid Go sever host" if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  end

  def validate_config
    %w(base_url repository_url).each do |var|
      raise_config_error "Missing configuration: #{var}" if send(var).to_s.empty?
    end
  end

  def base_url
    @base_url ||= data['base_url']
  end

  def repository_url
    @build_key ||= data['repository_url']
  end

  def username
    @username ||= data['username']
  end

  def password
    @password ||= data['password']
  end

  def verify_ssl
    # If verify SSL has never been set, let's default to true
    @verify_ssl ||= data['verify_ssl'].nil? || config_boolean_true?('verify_ssl')
  end
end
