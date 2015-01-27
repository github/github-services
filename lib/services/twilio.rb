class Service::Twilio < Service
  string   :account_sid, :from_phone, :to_phone
  boolean  :master_only
  password :auth_token
  white_list :account_sid, :from_phone, :to_phone

  def receive_push
    check_configuration_options(data)

    sms_body = "#{payload['pusher']['name']} has pushed #{payload['commits'].size} commit(s) to #{payload['repository']['name']}"
    send_message(data, sms_body) if send_notification?(data)
  end

  private

  def send_notification?(data)
    notify_user = true
    if data['master_only'].to_i == 1 && branch_name != 'master'
      notify_user = false
    end
    notify_user
  end

  def check_configuration_options(data)
    raise_config_error 'Account SID must be set' if data['account_sid'].blank?
    raise_config_error 'Authorization token must be set' if data['auth_token'].blank?
    raise_config_error 'Twilio-enabled phone number or short code must be set' if data['from_phone'].blank?
    raise_config_error 'Destination phone number must be set' if data['to_phone'].blank?
  end

  def send_message(data, message)
    client = ::Twilio::REST::Client.new(data['account_sid'], data['auth_token'])
    client.account.sms.messages.create(
      :from => data['from_phone'],
      :to => data['to_phone'],
      :body => message
    )
  end
end
