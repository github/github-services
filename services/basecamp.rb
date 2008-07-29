service :basecamp do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  payload['commits'].each do |commit|
    commid_id = commit['id']
    bc = Basecamp.new(data['url'], data['username'], data['password'])
    project_id = bc.projects.select { |p| p.name.downcase == data['project'].downcase }.first.id
    category_id = bc.message_categories(project_id).select { |category| category.name.downcase == data['category'].downcase }.first.id
    bc.post_message(project_id, {
      :title => "Commit Notification (#{repository}/#{branch}): #{commit_id}",
      :body => "`#{commit['message']}`, pushed by #{commit['author']['name']} (#{commit['author']['email']}). View more details for this change at #{commit['url']}.",
      :category_id => category_id
    })
  end
end
