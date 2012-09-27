class Service::Workmarket < Service

	string :token
	password :secret
	white_list :token
	default_events :push

	def auth_token
		http.url_prefix = 'https://www.workmarket.com/api/v1'
		http.headers['Accept'] = 'application/json'

		r = http_post 'authorization/request', {
			:token => data['token'],
			:secret => data['secret'],
			:type => 'json'
		}.to_query

		response = JSON.parse(r.body)
		token = response['response']['access_token']

		raise_config_error 'Invalid API token or secret' if token.empty?

		token
	end

	def receive_push
		token = auth_token

		commits.each do |commit|
			next if commit['message'] =~ /^x /

			commit['message'].match(/\[#(\d{10})\]/)

			next unless $1

			work_number = $1
			message = "#{commit['id'][0..6]} #{format_commit_message(commit)}"

			http_post 'assignments/add_note', {
				:access_token => token,
				:id => work_number,
				:content => message,
				:is_private => false
			}.to_query
		end
	end
end