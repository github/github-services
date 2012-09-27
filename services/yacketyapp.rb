require 'uri'
class Service::Yacketyapp < Service
    default_events :commit_comment, :issues, :issue_comment, :pull_request, :push
    string :room_key
    
    def receive_event
        if data['room_key'].to_s.empty?
            raise_config_error "The room key is missing :("
        end 
        hash = URI.escape(data['room_key'].to_s.gsub(/\s/, ''))
        
        http.headers['Content-Type'] = 'application/json'
        http_post "http://54.243.207.101/github/#{room_key}", JSON.generate(payload)
    end
end
