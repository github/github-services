class Service::Docker < Service

  url "http://www.Docker.io"

  # we don't have an offical logo yet, we will update when we get one.
  # logo_url "http://www.docker.io/"

  # kencochrane on GitHub/twitter is pinged for any bugs with the Hook code.
  maintained_by :github => 'kencochrane',
    :twitter => '@kencochrane'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :github => 'kencochrane',
    :twitter => '@getdocker'

  def receive_push
    http_post "https://index.docker.io/hooks/github", :payload => generate_json(payload)
  end
end

