class Service::GroupTalent < Service
  string :token

  def receive_push
    res = http_post "https://grouptalent.com/github/receive_push/#{data[:token]}",
      {'payload' => payload.to_json}

    if res.status != 200
      raise_config_error
    end
  end
end
