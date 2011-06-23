class Service::ZohoProjects < Service
  def receive_push
	res=http_post "https://projects.zoho.com/serviceHook",
	:pId => data['project_id'],
	:authtoken => data['token'],
	:scope => "projectsapi",
	:payload => JSON.generate(payload)
	if res.status != 200
      	raise_config_error
    	end
  end
end
