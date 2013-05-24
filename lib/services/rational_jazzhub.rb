class Service::RationalJazzHub < Service
	string   :username
	password :password
	white_list :username
	attr_accessor :cookies
	attr_accessor :server_url

	def receive_push
		checkSettings
		prepare
		authenticate
		postToJazzHub
	end
	
	def server_url
	    if !@server_url
    	   if data['server_url']
    	      @server_url = data['server_url']
    	   else
    	      @server_url = "https://hub.jazz.net/jts00"
    	   end
	    end
    	@server_url 
  	end

	def checkSettings
		raise_config_error "username not set" if data['username'].blank?
		raise_config_error "password not set" if data['password'].blank?
	end

	def prepare
#		http.ssl[:verify] = false
		http.headers['X-com-ibm-team-userid']= data['username']
#		http.builder.response :follow_redirects, {:cookie => :all}
		http.builder.response :logger
	end

	def authenticate
		form_based_authentification
	end

	def form_based_authentification
		res= http_get '%s/authenticated/identity' % server_url
		if not 'authrequired'.eql? res.headers['X-com-ibm-team-repository-web-auth-msg']
			# Expect one follow for WAS login
			if res.env[:status] == 302
				captureCookies res
				http.headers['Cookie']= cookieString
				res = http_get res.env[:response_headers][:location]
				if not 'authrequired'.eql? res.headers['X-com-ibm-team-repository-web-auth-msg']
					raise_config_error "Invalid authentication url. The response did not include a X-com-ibm-team-repository-web-auth-msg header"
				end
			else
				raise_config_error "Invalid authentication url. The response did not include a X-com-ibm-team-repository-web-auth-msg header"
			end
		end
		http.headers['Cookie']= captureCookies res
		http.headers['Content-Type']= 'application/x-www-form-urlencoded'

		res= http_post '%s/authenticated/j_security_check' % server_url, 
					   Faraday::Utils.build_nested_query(http.params.merge(:j_username => data['username'], :j_password => data['password'])) 

		if 'authrequired'.eql? res.headers['X-com-ibm-team-repository-web-auth-msg']
			raise_config_error 'Invalid Username or Password'
		end
	
		http.headers['Cookie']= captureCookies res
		http.headers['Content-Type']= ''
		res= http_get '%s/authenticated/identity' % server_url
		captureCookies res
	end
	
	def captureCookies (response)
		@cookies ||= Hash.new
		setstring = response.headers['set-cookie']
		if setstring
	    	setstring.split(/, (?=[\w]+=)/).each { | cookie |
   		 		# trim off the cookie domain and update info
        		cookiepair = cookie.split('; ')[0];
        		# split the key and value
        		cookieparts = cookiepair.split('=')
        		cookies[cookieparts[0]] = cookiepair[cookieparts[0].size+1..-1]
	    	}
        end
    	return cookieString
	end
	
	def cookieString
		result = ''
		if cookies 
			cookies.each { |key, value| 
				result += key + '=' + value + (cookies.size > 1 ? ";" : "")
			}
		end
		return result
	end
	
	def postToJazzHub
		http.headers['Content-Type']= 'application/json'
		http.headers['accept']= 'application/json'
		
	    res= http_post '%s/processGitHubPayload' % server_url, :payload => generate_json(payload)
		if !res.env[:status].between(200,299)
			raise_config_error 'Error posting payload to %s, response: %s' % ('%s/processGitHubPayload' % @server_url), res
		end
	end

end
