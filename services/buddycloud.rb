require 'rest-client'
require 'xmlsimple'
require 'time'

class Service::Buddycloud < Service
  self.title     = 'buddycloud (GitHub plugin)'
  self.hook_name = 'buddycloud' # legacy hook name
  
  string      :buddycloud_base_api, :username, :password, :channel
  password    :password
  boolean     :show_commits, :show_files
  white_list  :buddycloud_base_api, :username, :password, :channel

  def receive_push
    check_config data
    @time_format = '%c'
    entry         = create_entry payload
    make_request(entry, "posts")
  end
  
  def check_config(data)
    raise_config_error "buddycloud API base URL not set" if !data['buddycloud_base_api'].present? || data['buddycloud_base_api'].empty?
    raise_config_error "buddycloud username not set" if !data['username'].present? || data['username'].empty?
    raise_config_error "buddycloud password not set" if !data['password'].present? || data['password'].empty?
    raise_config_error "buddycloud channel not set" if !data['channel'].present? || data['channel'].empty?
    @url                 = data['buddycloud_base_api'] + '/' + data['channel'] + '/content/'
    @username            = data['username']
    @password            = data['password']
    @show_commit_summary = false
    @show_commit_detail  = false
    if data.has_key?('show_commit_summary') && data['show_commit_summary'] == true
      @show_commit_summary = true
    end
    if data.has_key?('show_commit_detail') && data['show_commit_detail'] == true
      @show_commit_detail  = true 
    end
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
  end
  
  def create_entry(payload)
    message = generate_message(payload)
    XmlSimple.xml_out(
      {
        'xmlns' => 'http://www.w3.org/2005/Atom',
        'content' => {'content' => message } 
      },
      {'RootName' => 'entry', 'NoIndent' => 1}
    )
  end
  
  def generate_message(payload)
    now     = Time.now
    message = <<-EOM
A push has been made to repository "#{payload['repository']['name']}"
    #{payload['repository']['url']}
      
Changes: #{payload['compare']}
Made by: #{payload['pusher']['name']} (https://github.com/#{payload['pusher']['name']})
When:    #{now.strftime(@time_format)}

EOM
    if @show_commit_summary == true
      i = 1
      message = message + "****** Commit summary ******\n"
      for commit in payload['commits']
        message = message + commit_summary_message(commit, i)
        i += 1
      end
    end
    message = message + "\n"
    if @show_commit_detail == true
      i = 1
      message = message + "****** Detailed commit information ******\n"
      for commit in payload['commits']
        message = message + commit_detail_message(commit, i)
        i += 1
      end
    end
    message = message + "\n\n"
  end
  
  def commit_summary_message(c, i)
    description = c['message'][0 .. 60]
    commit_message = <<-EOC
(#{i}) "#{description}"  - #{c['author']['name']}
EOC
  end

  def commit_detail_message(c, i)
    at             = Time.parse(c['timestamp'])
    added          = c['added'].join(' ')
    removed        = c['removed'].join(' ')
    modified       = c['modified'].join(' ')
    commit_message = <<-EOC
(#{i}) #{c['author']['name']} <#{c['author']['email']}>
#{at.strftime(@time_format)}    
#{c['url']}
Files added: #{added}
Files removed: #{removed}
Files modified: #{modified}

#{c['message']}  
-------------------------------------------------------------------------------
    
EOC
  end
end