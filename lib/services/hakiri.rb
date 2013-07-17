require_relative './http_post'

class Service::Hakiri < Service::HttpPost
  string :token, :project_id

  white_list :project_id

  default_events :push

  url 'https://www.hakiriup.com'
  logo_url 'http://files.hakiriup.com.s3.amazonaws.com/images/logo-small.png'

  maintained_by :github => 'vasinov',
                :twitter => '@vasinov'

  supported_by :web => 'https://www.hakiriup.com',
               :email => 'info@hakiriup.com',
               :twitter => '@vasinov'

  def receive_event
    token = required_config_value('token')
    project_id = required_config_value('project_id')

    if token.match(/^[A-Za-z0-9]+$/) == nil
      raise_config_error 'Invalid token'
    end

    if project_id.match(/^[0-9]+$/) == nil
      raise_config_error 'Invalid project ID'
    end

    url = "https://www.hakiriup.com/projects/#{project_id}/repositories/github_push?repo_token=#{token}"
    deliver url
  end
end
