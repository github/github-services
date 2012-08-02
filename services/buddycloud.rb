require 'rest-client'
require 'xmlsimple'

class Service::Buddycloud < Service
  self.title = 'buddycloud (GitHub plugin)'
  self.hook_name = 'buddycloud' # legacy hook name

  string :buddycloud_base_api
  white_list :buddycloud_base_api
  
  string      :buddycloud_base_api, :username, :password, :channel
  password    :password
  boolean     :on_commit, :on_pull_request, :on_events
  white_list  :buddycloud_base_api, :username, :password, :channel

  def receive_push
    check_config data
    @url      = data['buddycloud_base_api'] + '/' + data['channel'] + '/content/'
    @username = data['username']
    @password = data['password']
    entry     = create_entry "Github test"
    make_request(entry, "posts")
  end
  
  def check_config(data)
      raise_config_error "buddycloud API base URL not set" if !data['buddycloud_base_api'].present? || data['buddycloud_base_api'].empty?
      raise_config_error "buddycloud username not set" if !data['username'].present? || data['username'].empty?
      raise_config_error "buddycloud password not set" if !data['password'].present? || data['password'].empty?
      raise_config_error "buddycloud channel not set" if !data['channel'].present? || data['channel'].empty?
  end
  
  def make_request(entry, node)
    headers = { :accept => 'application/xml+atom', :content_type => :xml }
    headers['X-Session-Id'] = @session if defined? @session
    
    request = RestClient::Request.new(
        :method   => :post,
        :url      => @url + node,
        :user     => @username,
        :password => @password,
        :headers  => headers,
        :payload  => entry
    )
    begin
      response = request.execute
      @session = response.headers['X-Session-Id'] if defined? response.headers['X-Session-Id']
      response.code
    rescue 
      raise "buddycloud channel not responding as expected, post not made"
      return 500
  end
  
  def create_entry(message)
    XmlSimple.xml_out(
      {
        'xmlns' => 'http://www.w3.org/2005/Atom',
        'content' => {'content' => message } 
      },
      {'RootName' => 'entry', 'NoIndent' => 1})
  end
end
