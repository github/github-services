service :grmble do |data, payload|
  url = URI.parse("#{data['room_api_url']}/msg/")
  repository = payload[ 'repository' ][ 'name' ]
  branch = payload[ 'ref_name' ]
  commits = payload[ 'commits' ]

  $stdout.puts url

  commits.each do |commit|
    message = {
                'nickname' => 'github',
                'content' => "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} #{commit['url']}",
                'apiKey' => data[ 'token' ],
                'type' => 'message',
              }

    
    req = Net::HTTP::Post.new( url.path )
    req.set_form_data( 'message' => JSON.generate( message ) )

    http = Net::HTTP.new( url.host, url.port )
    http.use_ssl = true if url.port == 443 || url.instance_of?( URI::HTTPS )
    http.start { |http| http.request( req ) }
  end
end
