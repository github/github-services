service :basecamp do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last

  payload['commits'].each do |commit|
    basecamp    = Basecamp.new(data['url'], data['username'], data['password'])
    project_id  = basecamp.projects.select { |p| p.name.downcase == data['project'].downcase }.first.id
    category_id = basecamp.message_categories(project_id).select { |category| category.name.downcase == data['category'].downcase }.first.id

    basecamp.post_message(project_id, {
      :title => "Commit Notification (#{repository}/#{branch}): #{commit['id']}",
      :body => "`#{commit['message']}`, pushed by #{commit['author']['name']} (#{commit['author']['email']}). View more details for this change at #{commit['url']}.",
      :category_id => category_id
    })
  end
end
