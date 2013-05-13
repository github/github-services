class Service::Apiary < Service
  string :branch, :domain, :apiary_address
  white_list :branch

  url "http://apiary.io"
  logo_url "http://static.apiary.io/css/design2/apiary-io-symbol-1x.png"
  maintained_by :github => 'tu1ly'
  supported_by :web => 'http://support.apiary.io/',
    :email => 'support@apiary.io'

  APIARY_URL = "http://api.apiary.io/github/service-hook"
  
  def make_apiary_call
    return true if not domain
    http_post apiary_address,
      :payload => JSON.generate(payload),
      :branch => branch,
      :vanity => domain
  end

  def branch
    @branch ||= (not data['branch'].to_s.strip.empty?) ? data['branch'].to_s.strip : 'master'
  end

  def domain
    @domain ||= (not data['domain'].to_s.strip.empty?) ? data['domain'].to_s.strip : nil
  end
  
  def apiary_address
    @apiary_address ||= (not data['apiary_address'].to_s.strip.empty?) ? data['apiary_address'].to_s.strip : APIARY_URL
  end

  def receive_push
    return make_apiary_call
  end
end
