class Service::Cloud66 < Service::HttpPost
  string :redeployment_key

  default_events :push

  url "https://www.cloud66.com"
  logo_url "http://cdn.cloud66.com/images/cloud66_logo_140.png"

  maintained_by :github => 'cloud66'

  supported_by :web => 'https://www.cloud66.com',
    :email => 'support@cloud66.com',
    :twitter => '@cloud66'

  def receive_event
    redeployment_key = required_config_value('redeployment_key')

		redeployment_key = redeployment_key.gsub(/\s+/, "")

		if redeployment_key.size != 64
			raise_config_error "Invalid stack redeployment key"
		end

    url = "https://hooks.cloud66.com/stacks/redeploy/#{redeployment_key[0,32]}/#{redeployment_key[32,32]}"

    deliver url
  end
end
