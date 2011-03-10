# This code was pretty much copied from Ara Howard's
# RubyForge gem... thanks Ara! :)

require 'net/https'
require 'openssl'
require 'webrick/cookie'

class RubyForge
  def initialize(username, password)
    @cookies = Array.new
    login(username, password)
  end

  def post_news(group_id, subject, body)
    url = URI.parse('http://rubyforge.org/news/submit.php')
    form = {
      'group_id'     => group_id.to_s,
      'post_changes' => 'y',
      'summary'      => subject,
      'details'      => body,
      'submit'       => 'Submit'
    }
    execute(url, form)
  end

  #######
  private
  #######

  def login(username, password)
    url = URI.parse('https://rubyforge.org/account/login.php')
    form = {
      'return_to'      => '',
      'form_loginname' => username,
      'form_pw'        => password,
      'login'          => 'Login'
    }
    response = execute(url, form)
    bake_cookies(url, response)
  end

  def execute(url, parameters)
    request = Net::HTTP::Post.new(url.request_uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    @cookies.each do |cookie|
      request['Cookie'] = cookie
    end
    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request_data = query_string_for(parameters)
    request['Content-Length'] = request_data.length.to_s
    http.request(request, request_data)
  end

  def bake_cookies(url, response)
    (response.get_fields('Set-Cookie') || []).each do |raw_cookie|
      WEBrick::Cookie.parse_set_cookies(raw_cookie).each do |baked_cookie|
        baked_cookie.domain ||= url.host
        baked_cookie.path   ||= url.path
        @cookies << baked_cookie
      end
    end
  end

  def query_string_for(parameters)
    parameters.sort_by { |k,v| k.to_s }.map { |k,v|
      k && [ WEBrick::HTTPUtils.escape_form(k.to_s),
             WEBrick::HTTPUtils.escape_form(v.to_s) ].join('=')
    }.compact.join('&')
  end
end
