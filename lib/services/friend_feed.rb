class Service::FriendFeed < Service
  string :nickname, :remotekey
  white_list :nickname

  def receive_push
    repository = payload['repository']['name']
    friendfeed_url = "http://friendfeed.com/api/share"

    payload['commits'].each do |commit|
      title = "#{commit['author']['name']} just committed a change to #{repository} on GitHub"
      comment = "#{commit['message']} (#{commit['id']})"

      http.basic_auth data['nickname'], data['remotekey']
      http_post friendfeed_url,
        :title => title, :link => commit['url'], :comment => comment, :via => :github
    end
  end
end
