# based on the travis.rb service
class Service::Nodejitsu < Service
  string :username
  password :password
  string :branch, :endpoint
  boolean :email_success_deploys, :email_errors
  white_list :endpoint, :username, :branch, :email_success_deploys, :email_errors

  def receive_push
    return if branch.to_s != '' && branch != branch_name
    http.ssl[:verify] = false
    http.basic_auth username, password
    http_post nodejitsu_url, :payload => generate_json(payload),
      :email_success => email_success_deploys, :email_errors => email_errors
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
      'master'
    else
       data['branch']
    end.strip
  end

  def password
    if data['password'].to_s == ''
      ''
    else
       data['password']
    end.strip
  end

  def email_success_deploys
    data['email_success_deploys']
  end

  def email_errors
    data['email_errors']
  end

  def scheme
    domain_parts.size == 1 ? 'https' : domain_parts.first
  end

  def domain
    domain_parts.last
  end

  protected

  def full_domain
    if data['endpoint'].to_s == ''
      'https://webhooks.nodejitsu.com'
    else
      data['endpoint']
    end.strip
  end

  def domain_parts
    @domain_parts ||= full_domain.split('://')
  end
end
