class Service::Puppetlinter < Service

  def receive_push
    url = URI.parse('http://www.puppetlinter.com/api/v1/hook')
    http_post url, payload.to_json, 'Content-Type' => 'application/json'
  end
end
