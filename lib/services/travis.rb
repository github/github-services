class Service::Travis < Service
  default_events :push, :pull_request, :issue_comment, :public, :member
  string :user
  password :token
  string :domain
  white_list :domain, :user

  def receive_event
    http.ssl[:verify] = false
    http.basic_auth user, token
    http.headers['X-GitHub-Event'] = event.to_s
    http.headers['X-GitHub-GUID'] = delivery_guid.to_s
    http_post travis_url, :payload => generate_json(payload)
  end

  def travis_url
    "#{scheme}://#{domain}"
  end

  def user
    if data['user'].to_s == ''
      owner_payload['login'] || owner_payload['name']
    else
      data['user']
    end.strip
  end

  def token
    data['token'].to_s.strip
  end

  def scheme
    domain_parts.size == 1 ? 'http' : domain_parts.first
  end

  def domain
    domain_parts.last
  end

  protected

  def owner_payload
    payload['repository']['owner']
  end

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

