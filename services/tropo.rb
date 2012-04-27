class Service::Tropo < Service
  string   :from_number, :to_number
  password :token

  def receive_push
    if data["destination"].blank?
      raise_config_error 'Destination phone number(s) must be provided'
    elsif data["token"].blank?
      raise_config_error 'Application token must be provided'
    end

    send_message(data,{
                       :msg=>"#{payload["pusher"]["name"]} has just pushed #{payload["commits"].size} commit(s) to #{payload["repository"]["name"]}",
                       :network=>data["network"] ? data["network"] : 'sms'
                       })
  end

  private

  def send_message(data,opts={})
    opts={:network=>'sms'}.merge!(opts)

    http_get("https://api.tropo.com/1.0/sessions?action=create",
                  :destination=>data["to_number"],
                  :token => data["token"],
                  :msg_to_send=>opts[:msg],
                  :network=>opts[:network])
  end
end