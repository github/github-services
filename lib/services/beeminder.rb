class Service::Beeminder < Service
	string :username, :goal_slug, :auth_token
	white_list :username, :goal_slug, :auth_token

	url "http://www.beeminder.com"
	logo_url "https://www.beeminder.com/favicon.png"

	maintained_by :github  => 'ThomasMatlak'
	supported_by  :web     => 'https://www.beeminder.com/contact',
				  :email   => 'support@beeminder.com',
				  :twitter => '@bmndr'

	def receive_push
	
		require 'net/http'
		require 'uri'
		
		username = data['username']
		goal_slug = data['goal_slug']
		auth_token = data['auth_token']

		uri = URI.parse("https://www.beeminder.com/api/v1/users/#{username}/goals/#{goal_slug}/datapoints.json")
		params = {"auth_token" => "#{auth_token}", "value" => "1", "comment" => "Auto-entered from GitHub commit"}

		Net::HTTP.post_form(uri, params)
	
	end
end
