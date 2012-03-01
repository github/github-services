class Service::Packagist < Service
  string :domain, :user, :token

  def receive_push
    http.ssl[:verify] = false
    r = http_post packagist_url, :payload => payload.to_json, :username => user, :apiToken => token
    puts r.body
    puts r.status
    puts r.headers
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
      'http://packagist.org'
    else
      data['domain']
    end.strip
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end

