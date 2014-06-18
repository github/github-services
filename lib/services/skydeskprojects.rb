# encoding: utf-8
class Service::SkyDeskProjects < Service::HttpPost
  string :project_id
  password :token

  white_list :project_id

  url "https://www.skydesk.jp"
  logo_url "https://www.skydesk.jp/static/common/images/header/ci/ci_skydesk.gif"

  maintained_by :github => 'SkyDeskProjects'

  supported_by :web => 'www.skydesk.jp/en/contact/',
    :email => 'support_projects@skydesk.jp'

   def receive_push
    token = required_config_value('token')
    pId = required_config_value('project_id')
    #http.headers['Authorization'] = "Token #{token}"

    #url = "https://projects.skydesk.jp/serviceHook"
    res = http_post "https://projects.skydesk.jp/serviceHook",
      :pId       => pId,
      :authtoken => token,
      :scope     => "projectsapi",
      :payload   => generate_json(payload)
    if res.status != 200
      raise_config_error
    end
  end
end
