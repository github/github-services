class Service::RubyDocInfo < Service
  def receive_push
    http_post 'http://rubydoc.info/checkout', :payload => payload.to_json
  end
end
