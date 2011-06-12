class Service::Commitify < Service
  def receive_push
    http_post "http://commitify.appspot.com/commit",
      # Private key (for private repositories, share with your developers)
      :key => data['private_key'],
      :payload => JSON.generate(payload)
  end
end
