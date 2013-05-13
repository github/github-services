class Service::GroupTalent < Service
  string :token

  def receive_push
    res = http_post "https://grouptalent.com/github/receive_push/#{data[:token]}",
      {'payload' => generate_json(payload)}

    if res.status != 200
      raise_config_error
    end
  end
end
