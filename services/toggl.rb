require "net/http"
require "json"
require "time"

module Toggl
  
  class Remote
    
    base_uri = "https://www.toggl.com/api/v5/"
    
    def initialize(api_key)
      @api_key = api_key
    end
    
    
    def create_task(data)
      post("tasks", data)
    end
    
    
    def get(method, data = {})
      uri = URI.parse("https://www.toggl.com/api/v5/#{method}.json")
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      
      request = Net::HTTP::Get.new(uri.request_uri)
      request.set_content_type("application/json")
      request.basic_auth(@api_key, "api_token")
      request.body = data.to_json

      puts http.request(request)
    end
    
    
    def post(method, data = {})
      uri = URI.parse("https://www.toggl.com/api/v5/#{method}.json")
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_content_type("application/json")
      request.basic_auth(@api_key, "api_token")
      request.body = data.to_json

      puts http.request(request)
    end
  end
  
end


service :toggl do |data, payload|

  payload["commits"].each do |commit|

    duration = (commit["message"].split(/\s/).find { |item| /t:/ =~ item } || "")[2,100]
    next unless duration

    # Toggl wants it in seconds.  Commits should be in seconds
    duration = duration.to_i * 60

    toggl = Toggl::Remote.new(data["api_token"])
    toggl.create_task(
      :task => {
        :duration => duration.to_i,
        :description => commit["message"].strip,
        :project => data["project"],
        :start => (Time.now - duration.to_i).iso8601,
        :billable => true,
        :created_with => "github",
        :stop => Time.now.iso8601
      }
    )

  end
  
end