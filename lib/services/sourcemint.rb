class Service::Sourcemint < Service
  def receive_push
    http_post 'http://api.sourcemint.com/actions/post-commit',
      :payload => generate_json(payload)
  end
end
