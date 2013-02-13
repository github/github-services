class Service::RapidPush < Service
  string :apikey
  self.title = 'RapidPush'
  url "http://rapidpush.net"
  logo_url "http://rapidpush.net/templates/rapidpush/images/logo.png"

  # PrDatur on GitHub is pinged for any bugs with the Hook code.
  maintained_by :github => 'prdatur'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://rapidpush.net/admin/content/view/9',
    :email => 'info@rapidpush.net'

  def receive_push
    return unless payload['commits']

    url = URI.parse('https://rapidpush.net/api')
    repository = payload['repository']['url'].split("/")
    title = [repository[-2], repository[-1]].join('/')
    category = "GitHub"
    message = "#{payload['commits'].length} commits pushed to #{category} (#{payload['commits'][-1]['id'][0..7]}..#{payload['commits'][0]['id'][0..7]})<br/>
<br/>
Latest Commit by #{payload['commits'][-1]['author']['name']}<br/>
#{payload['commits'][-1]['id'][0..7]} #{payload['commits'][-1]['message']}<br/>
<br/>
<a href='#{payload['compare']}'>URL</a>"

    http_post 'https://rapidpush.net/api',
      :apikey => data['apikey'],
      :category => category,
      :title => title,
      :message => message
  end
end
