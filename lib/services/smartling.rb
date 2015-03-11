class Service::Smartling < Service

  url "http://smartling.com"

  maintained_by :github => 'smartling'

  supported_by :web => 'http://support.smartling.com',
               :email => 'support@smartling.com'

  string :service_url, :project_id
  password :api_key
  string :config_path
  boolean :master_only
  white_list :service_url, :project_id, :config_path

  def receive_push
    check_config
    if data["master_only"] == nil || data["master_only"] == false || payload["ref"] == "refs/heads/master"
        payload["projectId"] = data["project_id"]
        payload["apiKey"] = data["api_key"]
        payload["resourceFile"] = data["config_path"]

        http.url_prefix = data["service_url"].to_s
        res = http_post "github", generate_json(payload)

        if res.status < 200 || res.status > 299
           raise_config_error "Status: " + res.status.to_s + ", body: " + res.body
        end
    end
  end

  def check_config
    raise_config_error "Missing smartling broker url" if data["service_url"].to_s.empty?
    raise_config_error "Missing project id" if data["project_id"].to_s.empty?
    raise_config_error "Missing smartling api key" if data["api_key"].to_s.empty?
    raise_config_error "Missing path to the project configuration" if data["config_path"].to_s.empty?
  end

end
