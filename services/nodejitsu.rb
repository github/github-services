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
    "#{scheme}://#{domain}/deploy"
  end

  def username
    if data['username'].to_s == ''
      payload['repository']['owner']['name']
    else
      data['username']
    end.strip
  end

  def branch
    data['branch'].strip
  end

  def password
    data['password'].strip
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
      'http://github.jit.su'
    else
      data['domain']
    end.strip
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end