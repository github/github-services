class Service::Travis < Service
  string :user, :token, :domain

  def receive_push
    http.ssl[:verify] = false
    http.basic_auth user, token
    http_post travis_url, :payload => payload.to_json
  end

  def travis_url
    "#{scheme}://#{domain}"
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
    if data['domain'].present?
      data['domain']
    else
      'http://notify.travis-ci.org'
    end.strip
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end

