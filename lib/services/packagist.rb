class Service::Packagist < Service
  string :user
  password :token
  string :domain
  white_list :domain, :user

  def receive_push
    http_post packagist_url, :payload => generate_json(payload), :username => user, :apiToken => token
  end

  def packagist_url
    "#{scheme}://#{domain}/api/github"
  end

  def user
    if data['user'].to_s == ''
      payload['repository']['owner']['name']
    else
      data['user']
    end.strip
  end

  def token
    data['token'].strip
  end

  def scheme
    domain_parts.size == 1 ? 'http' : domain_parts.first
  end

  def domain
    domain_parts.last
  end

  protected

  def full_domain
    if data['domain'].to_s == ''
      'https://packagist.org'
    else
      data['domain']
    end.lstrip.sub(/[\/\s]+$/,'').sub(/^http:\/\/packagist.org/, 'https://packagist.org')
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end
