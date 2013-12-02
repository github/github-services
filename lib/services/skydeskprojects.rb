class Service::SkyDeskProjects < Service::HttpPost
  string :project_id, :token
  
  white_list :project_id

  url "https://www.skydesk.jp"
  logo_url "https://www.skydesk.jp/static/common/images/header/ci/ci_skydesk.gif"
  
  maintained_by :github => 'SkyDeskProjects'
   
  supported_by :web => 'www.skydesk.jp/en/contact/',
    :email => 'support_projects@skydesk.jp'
    
   def receive_push
    token = required_config_value('token')
    
    http.headers['Authorization'] = "Token #{token}"

    url = "https://projects.skydesk.jp/serviceHook",
      :payload => generate_json(payload),
      :pId => data['project_id'],
      :authtoken => data['token'],
      :scope => "projectsapi"
    deliver url
  end
end
