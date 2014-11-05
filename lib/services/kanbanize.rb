class Service::Kanbanize < Service
  string :kanbanize_domain_name
  string :kanbanize_api_key

  # only include 'kanbanize_domain_name' in the debug logs, skip the api key.
  white_list :kanbanize_domain_name

  url "https://kanbanize.com/"
  logo_url "https://kanbanize.com/application/resources/images/logo.png"

  maintained_by :github => 'DanielDraganov'
  supported_by  :email => 'office@kanbanize.com'

  def receive_push
    domain_name = data['kanbanize_domain_name']
    api_key = data['kanbanize_api_key']

     http_post "http://#{domain_name}/index.php/api/kanbanize/git_hub_event",
      generate_json(payload),
      'apikey' => api_key,
      'Content-Type' => 'application/json'
  end
end
