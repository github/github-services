module TeamCity
  class Remote

    def initialize(data = {})
      @base_url, @build_type_id, @username, @password = data['base_url'], data['build_type_id'], data['username'], data['password']
      instance_variables.each{|var| raise GitHub::ServiceConfigurationError.new("Missing configuration: #{var}") if instance_variable_get(var).to_s.empty? }
      @uri = URI.parse(@base_url.gsub(/\/$/, ''))
      @conn = Net::HTTP.new(@uri.host, @uri.port)
      @conn.use_ssl = @uri.scheme.eql?("https")
      @conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    
    def trigger_build
      @conn.start do |http|
        req = Net::HTTP::Get.new(@uri.path + '/httpAuth/action.html?add2Queue=' + CGI.escape(@build_type_id))
        req.basic_auth @username, @password
        resp = http.request(req)
        if resp
          # TeamCity REST API never returns a body
          # but at least raise an HTTP error if response.code is not 2xx
          resp.value
        end
      end 
    end
    
  end
end

service :teamcity do |data, payload|
  begin
    TeamCity::Remote.new(data).trigger_build
  rescue SocketError => e
    raise GitHub::ServiceConfigurationError.new("Invalid TeamCity host name") if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  rescue => e
    case e.to_s
      when /\((?:403|401|422)\)/ then raise GitHub::ServiceConfigurationError, "Invalid credentials"
      when /\((?:404|301|302)\)/ then raise GitHub::ServiceConfigurationError, "Invalid TeamCity URL"
      else raise
    end
  end
end
