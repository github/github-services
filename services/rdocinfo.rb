class Service::RubyDocInfo < Service
  self.hook_name = :rubydocinfo

  def receive_push
    http_post 'http://rubydoc.info/checkout', :payload => payload.to_json
  end
end
