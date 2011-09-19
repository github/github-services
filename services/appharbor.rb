class Service::AppHarbor < Service
  string :create_build_url
  
  def receive_push
    raise_config_error 'Missing Create build URL' if data['create_build_url'].to_s.empty?
  end
end
