class Service::Namecast < Service::HttpPost

  url "https://www.namecast.net"

  logo_url "https://www.namecast.net/logo.jpg"

  # namebot on GitHub and Namecast on twitter are pinged for any bugs with the hook code.
  maintained_by :github => 'namebot',
    :twitter => '@Namecast'

  # Support channels for user-level hook problems (service failure,
  # misconfigured options, domain weirdness, etc.
  supported_by :github => 'namebot',
    :twitter => '@Namecast'

  def receive_event
    deliver "https://www.namecast.net/hooks/dnssync.php"
  end
end

