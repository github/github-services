class Service::Prowl < Service
  def receive_push
    # FIXME
    http.ssl[:verify] = false

    url = URI.parse('https://api.prowlapp.com/publicapi/add')
    repository = payload['repository']['url'].split("/")
    event = repository[-2], "/", repository[-1]
    application = "GitHub"
    description = "#{payload['commits'].length} commits pushed to #{application} (#{payload['commits'][-1]['id'][0..7]}..#{payload['commits'][0]['id'][0..7]})
    
  Latest Commit by #{payload['commits'][-1]['author']['name']}
  #{payload['commits'][-1]['id'][0..7]} #{payload['commits'][-1]['message']}"

    http_post 'https://api.prowlapp.com/publicapi/add',
      :apikey => data['apikey'],
      :application => application,
      :event => event,
      :description => description,
      :url => payload['compare']
  end
end
