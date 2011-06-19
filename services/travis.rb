class Service::Travis < Service
  def receive_push
    http.ssl[:verify] = false
    http.basic_auth user, token
    http_post travis_url, :payload => payload.to_json
  end

  def travis_url
    "#{scheme}://#{domain}/builds"
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
      'http://travis-ci.org'
    else
      data['domain']
    end.strip
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end

