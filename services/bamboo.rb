module Bamboo
  class Remote

    def initialize(data = {})
      @base_url, @build_key, @username, @password = data['base_url'], data['build_key'], data['username'], data['password']
      instance_variables.each{|var| raise GitHub::ServiceConfigurationError.new("Missing configuration: #{var}") if instance_variable_get(var).to_s.empty? }
      @uri = URI.parse(@base_url.gsub(/\/$/, ''))
      @conn = Net::HTTP.new(@uri.host, @uri.port)
      @conn.use_ssl = @uri.scheme.eql?("https")
      @conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def trigger_build
      authenticated do |token|
        @conn.start do |http|
          resp = http.post(@uri.path + "/api/rest/executeBuild.action", "auth=#{CGI.escape(token)}&buildKey=#{CGI.escape(@build_key)}")
          if resp
            message = XmlSimple.xml_in(resp.body)
            raise GitHub::ServiceConfigurationError.new(message["error"]) if message["error"]
          end
        end 
      end
    end

    def authenticated
      token = nil
      begin
        token = login
        yield token
      ensure
        logout(token)
      end
    end

    def login
      @conn.start do |http|
        response = http.post(@uri.path + "/api/rest/login.action", "username=#{CGI.escape(@username)}&password=#{CGI.escape(@password)}")
        if response && (200..204).include?(response.code.to_i)
          XmlSimple.xml_in(response.body)["auth"].first
        else
          raise StandardError, "Failed to login (#{response.code})"
        end
      end
    end

    def logout(token)
      @conn.start do |http|
        http.post(@uri.path + "/api/rest/logout.action", "auth=#{CGI.escape(token)}")
      end if token
    end
  end
end

service :bamboo do |data, payload|
  begin
    Bamboo::Remote.new(data).trigger_build
  rescue SocketError => e
    raise GitHub::ServiceConfigurationError.new("Invalid Bamboo host name") if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  rescue => e
    case e.to_s
      when /\((?:403|401|422)\)/ then raise GitHub::ServiceConfigurationError, "Invalid credentials"
      when /\((?:404|301)\)/ then raise GitHub::ServiceConfigurationError, "Invalid Bamboo project URL"
      else raise
    end
  end
end
