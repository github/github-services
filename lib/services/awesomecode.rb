class Service::Awesomecode < Service
  string :project_id

  white_list :project_id

  url 'https://awesomecode.io'

  maintained_by github: 'yonggu'

  supported_by github: 'yonggu'

  def receive_push
    raise_config_error "Missing 'project_id'" if data['project_id'].to_s == ''

    http_post awesomecode_url, :payload => generate_json(payload)
  end

  private

  def awesomecode_url
    "https://awesomecode.io/projects/#{data['project_id']}/builds"
  end
end
