class Service::Toggl < Service
  string :project
  password :api_token
  white_list :project

  def receive_push
    http.url_prefix = "https://www.toggl.com/api/v8"
    http.basic_auth data['api_token'], 'api_token'
    http.headers['Content-Type'] = 'application/json'

    payload["commits"].each do |commit|
      duration = (commit["message"].split(/\s/).find { |item| /t:/ =~ item } || "")[2,100]
      next unless duration

      # Toggl wants it in seconds.  Commits should be in seconds
      duration = duration.to_i * 60

      http_post "tasks.json", generate_json(
        :task => {
          :duration => duration.to_i,
          :description => commit["message"].strip,
          :project => {
            :id => data["project"]
          },
          :start => (Time.now - duration.to_i).iso8601,
          :billable => true,
          :created_with => "github",
          :stop => Time.now.iso8601
        }
      )

    end
  end
end
