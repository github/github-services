class Service::OnTime < Service
	string :ontime_url, :api_key
	
	def receive_push
		if data['ontime_url'].to_s.empty?
			raise_config_error "No OnTime URL to connect to."
		elsif data['api_key'].to_s.empty?
			raise_config_error "No API Key."
		end
		
		owner 		= payload['repository']['owner']['name']
		repo_name 	= payload['repository']['name']
		
		payload['commits'].each do |commit|
			files 			= commit['added'] | commit['modified'] | commit['removed']
			ontime_items	= Array.new
			
			# Look to see if there is a OnTime item id/type in the commit message
			# [OnTime.<type>.<id>] [OnTime.defect.5] [ontime.d.5] [ontime.t.123] [ontime.task.123]
			# This is a commit comment [ontime.defect.5] and it belongs also to [ontime.task.123]
			ontime_item_ids = commit['message'].scan(/\[[\s]*ontime\.(defect|feature|task)\.([1-9][0-9]*)[\s]*\]/i)
			
			ontime_item_ids.each do |ot_item|
				item = {}
				item['type'] 	= ot_item.at(0)
				item['id']		= ot_item.at(1)
				ontime_items << item
			end
			
			if ontime_items.size != 0
				http.headers['Content-Type'] = 'application/json'
				http.url_prefix = data['ontime_url']
				
				postdata = {}
				postdata['commit_msg']		= commit['message']
				postdata['commit_url']		= commit['url']
				postdata['commit_id']		= commit['id']
				postdata['commit_time']		= commit['timestamp']
				postdata['commit_author']	= commit['author']['name']
				postdata['ontime_items']	= ontime_items
				postdata['files'] 			= Array.new
				
				files.each do |file|
					file_with_url = {}
					file_with_url['filename'] = file
					file_with_url['url'] = "https://github.com/" + owner + "/" + repo_name + "/blob/" + commit['id'] + "/" + file
					
					postdata['files'] << file_with_url
				end
				
				http_post "api/github", postdata.to_json
			end
		end
	end
end