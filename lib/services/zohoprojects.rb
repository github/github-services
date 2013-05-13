class Service::ZohoProjects < Service
  string :project_id, :token
  white_list :project_id

  def receive_push
    res = http_post "https://projects.zoho.com/serviceHook",
      :pId       => data['project_id'],
      :authtoken => data['token'],
      :scope     => "projectsapi",
      :payload   => generate_json(payload)
    if res.status != 200
      raise_config_error
    end
  end
end
