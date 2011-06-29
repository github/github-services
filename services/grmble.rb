class Service::Grmble < Service
  string :room_api_url, :token

  def receive_push
    http.url_prefix = data['room_api_url'].to_s
    repository = payload[ 'repository' ][ 'name' ]
    branch = payload[ 'ref_name' ]
    commits = payload[ 'commits' ]

    commits.each do |commit|
      message = {
                  'nickname' => 'github',
                  'content' => "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} #{commit['url']}",
                  'apiKey' => data[ 'token' ],
                  'type' => 'message',
                }

      http_post 'msg', :message => JSON.generate(message)
    end
  end
end
