class Service::Docker < Service::HttpPost

  url "http://www.docker.com"
  logo_url "http://www.docker.com/static/img/nav/docker-logo-loggedout.png"

  # kencochrane on GitHub/twitter is pinged for any bugs with the Hook code.
  maintained_by :github => 'kencochrane',
    :twitter => '@kencochrane'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :github => 'kencochrane',
    :twitter => '@docker'

  def receive_event
    deliver "https://registry.hub.docker.com/hooks/github"
  end
end

