class Service::Twilio < Service
  string   :account_sid, :from_phone, :to_phone
  password :auth_token
  
  def receive_push
    check_configuration_options(data)
    
    sms_body = "#{payload['pusher']['name']} has pushed #{payload['commits'].size} commit(s) to #{payload['repository']['name']}"
    client = ::Twilio::REST::Client.new(data['account_sid'], data['auth_token'])
    client.account.sms.messages.create(
      :from => data['from_phone'],
      :to => data['to_phone'],
      :body => sms_body
    )
  end
  
  private
  
  def check_configuration_options(data)
    raise_config_error 'Account SID must be set' if data['account_sid'].blank?
    raise_config_error 'Authorization token must be set' if data['auth_token'].blank?
    raise_config_error 'Twilio-enabled phone number or short code must be set' if data['from_phone'].blank?
    raise_config_error 'Destination phone number must be set' if data['to_phone'].blank?
  end
end