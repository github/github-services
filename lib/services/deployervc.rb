require 'uri'

class Service::Deployervc < Service::HttpPost
  string :deployment_address
  password  :api_token

  white_list :deployment_address
  
  default_events :push

  url "https://deployer.vc"

  maintained_by :github => 'deployervc-emre'

  supported_by :web => 'https://deployer.vc/support.html',
               :email => 'support@deployer.vc'


  def receive_event
    deploymentaddress = required_config_value('deployment_address')
    apitoken = required_config_value('api_token')

    begin
      URI.parse(deploymentaddress)
    rescue URI::InvalidURIError
      raise_config_error("Invalid URL for deployment address: #{deploymentaddress}")
    end

    parts = URI.split(deploymentaddress)
    scheme = parts[0]
    host = parts[2]
    path = parts.last
    deployment_id = path.split('/').last

    http.headers['X-Deployervc-Token'] = apitoken
    http.headers['Content-Type']       = 'application/json'
    http.headers['Accept']             = 'application/json'

    http.url_prefix = "#{scheme}://#{host}"

    url = "/api/v1/deployments/deploy/#{deployment_id}"
    http_post(url, generate_json({:revision => ''}))
  end
end