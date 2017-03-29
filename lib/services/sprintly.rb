class Service::Sprintly < Service
  default_events :commit_comment, :create, :delete, :download,
      :follow, :fork, :fork_apply, :gist, :gollum, :issue_comment,
      :issues, :member, :public, :pull_request, :push, :team_add,
      :watch, :pull_request_review_comment, :status
  string :email, :api_key, :product_id
  white_list :email, :product_id

  def receive_event
    raise_config_error "Must provide an api key" if data['api_key'].to_s.empty?
    raise_config_error "Must provide an email address." if data['email'].to_s.empty?
    raise_config_error "Must provide a product id." if data['product_id'].to_s.empty?
    host_name = ENV['SPRINTLY_DEBUG_HOST'] || "https://sprint.ly"

    http.headers['Content-Type'] = 'application/json'
    http.basic_auth(data['email'], data['api_key'])

    http_post "#{host_name}/integration/github/#{data['product_id']}/#{event}/", generate_json(payload)
  end
end

