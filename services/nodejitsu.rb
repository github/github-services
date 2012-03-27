# based on the travis.rb service
class Service::Nodejitsu < Service
  string :subdomain, :username, :branch 
  password :password

  def receive_push
    return if branch.to_s != '' && branch != branch_name
    http.ssl[:verify] = false
    http.basic_auth username, password
    http_post nodejitsu_url, :payload => payload.to_json
  end

  def nodejitsu_url
    "#{scheme}://#{domain}/1/deploy"
  end

  def username
    if data['username'].to_s == ''
      payload['repository']['owner']['name']
    else
      data['username']
    end.strip
  end

  def branch
    if data['branch'].to_s == ''
      data['branch']
    else
       'master'
    end.strip
  end

  def password
    if data['password'].to_s == ''
      data['password']
    else
       ''
    end.strip
  end

  def scheme
    domain_parts.size == 1 ? 'https' : domain_parts.first
  end

  def domain
    domain_parts.last
  end

  protected

  def full_domain
    if data['domain'].to_s == ''
      'https://webhooks.nodejitsu.com'
    else
      data['domain']
    end.strip
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end