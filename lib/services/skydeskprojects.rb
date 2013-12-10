# encoding: utf-8
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
    pId = required_config_value('project_id')
    body = {'pId'=>pId, 'authtoken'=>token,:scope => 'projectsapi' , 'payload'=>payload}
    body = generate_json(body)     
    #http.headers['Authorization'] = "Token #{token}"

    url = "https://projects.skydesk.jp/serviceHook"
    deliver url
  end
end
