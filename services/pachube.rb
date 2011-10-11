class Service::Pachube < Service
  string :api_key
  string :feed_id

  def receive_push
    raise_config_error "Missing api_key" if data['api_key'].to_s.empty?
    raise_config_error "Missing feed_id" if data['feed_id'].to_s.empty?

    http_method :put, "https://api.pachube.com/v2/feeds/#{data['feed_id']}.json" do |req|
      req.headers['X-PachubeApiKey'] = data['api_key']
      req.body = {
        :version => '1.0.0',
        :datastreams => [
          {
            :id => repo_name,
            :current_value => distinct_commits.size
          }
        ]}.to_json
    end
  end
end
