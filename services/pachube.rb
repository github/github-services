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
            :id => "#{repo_name}.commits_pushed",
            :current_value => distinct_commits.size
          }
        ]}.to_json
    end

    payload['commits'].each do |commit|
      http_method :put, "https://api.pachube.com/v2/feeds/#{data['feed_id']}.json" do |req|
        req.headers['X-PachubeApiKey'] = data['api_key']
        req.body = {
          :version => '1.0.0',
          :datastreams => [
            {
              :id => "#{repo_name}.modified_files",
              :current_value => commit['modified']
            },
            {
              :id => "#{repo_name}.added_files",
              :current_value => commit['added']
            },
            {
              :id => "#{repo_name}.removed_files",
              :current_value => commit['removed']
            }
          ]}.to_json
      end
    end
  end
end
