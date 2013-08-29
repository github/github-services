class Service::Crisco < Service::HttpPost
  string :crisco_url
  white_list :crisco_url

  default_events :push, :commit_comment,
    :pull_request, :pull_request_review_comment

  url "http://crisco-review.herokuapp.com/"
  logo_url "http://crisco-review.herokuapp.com/logo.png"

  maintained_by :github => 'darvin',
    :twitter => '@sergey_v_klimov'

  supported_by :web => 'https://github.com/darvin/crisco/issues',
    :email => 'sergey.v.klimov@gmail.com',
    :twitter => '@sergey_v_klimov'

  def receive_event
    crisco_url_config = config_value('crisco_url')
    crisco_url =  crisco_url_config && crisco_url_config.length>0 ? crisco_url_config : "http://crisco-review.herokuapp.com/"

    url = "#{crisco_url}/webhook"
    deliver url
  end
end
