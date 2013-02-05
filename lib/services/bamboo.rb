class Service::Bamboo < Service
  string   :base_url, :build_key, :username
  password :password
  white_list :base_url, :build_key, :username

  def receive_push
    verify_config
    branch = payload['ref']
    trigger_build(branch)
  rescue SocketError => e
    if e.to_s =~ /getaddrinfo: Name or service not known/
      raise_config_error("Invalid Bamboo host name")
    else
      raise
    end
  end

  def trigger_build(ref)
    # Post body is empty but Bamboo REST expects this to be set (in 3.x)
    http.headers['Content-Type'] = 'application/xml'

    commit_branch = ref.split('/').last

    build_key.split(',').each do |branch_key|
      #See if the split result is just a key or a branch:key
      parts = branch_key.split(':')
      key = parts[0]
      if parts.length == 2
        branch = parts[0]
        key = parts[1]

        #Has a branch, verify it matches the branch for the commit
        next unless branch == commit_branch
      end

      res = http_post "rest/api/latest/queue/#{key}"
      handle_response(res)
    end
  end

  def handle_response(response)
    case response.status
      when 200..204
        "Ok"
      when 403, 401, 422 then raise_config_error("Invalid credentials")
      when 404, 301 then raise_config_error("Invalid Bamboo project URL")
      else
        maybe_xml = response.body
        msg = (XmlSimple.xml_in(maybe_xml) if maybe_xml =~ /<?xml/) || {}
        raise_config_error msg["message"] if msg["message"]
      end
  end

  def verify_config
    %w(base_url build_key username password).each do |var|
      raise_config_error "Missing configuration: #{var}" if send(var).to_s.empty?
    end
    http.ssl[:verify] = false
    http.url_prefix   = base_url
    http.basic_auth(username, password)
  end

  def base_url
    @base_url ||= data['base_url'].gsub(/\/$/, '')
  end

  def build_key
    @build_key ||= data['build_key']
  end

  def username
    @username ||= data['username']
  end

  def password
    @password ||= data['password']
  end
end
