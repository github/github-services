require 'xmlsimple'
require 'time'

class Service::Buddycloud < Service
  self.title     = 'buddycloud (GitHub plugin)'
  self.hook_name = 'buddycloud' # legacy hook name

  string      :buddycloud_base_api, :username, :password, :channel
  password    :password
  boolean     :show_commit_summary, :show_commit_detail
  white_list  :buddycloud_base_api, :username, :channel, :show_commit_summary, :show_commit_detail

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
    if data.has_key?('show_commit_summary') && data['show_commit_summary'].to_i == 1
      @show_commit_summary = true
    end
    if data.has_key?('show_commit_detail') && data['show_commit_detail'].to_i == 1
      @show_commit_detail  = true 
    end
  end

  def make_request(entry, node)

    http.basic_auth @username, @password
    http.headers['Content-Type'] = 'application/xml'
    http.headers['X-Session-Id'] = @session if defined? @session
    http.ssl[:verify]            = false
    response                     = http_post @url + node, entry

    @session = response.headers['X-Session-Id'] if defined? response.headers['X-Session-Id']
    case response.status
      when 403, 401, 422 then raise_config_error("Permission denied")
      when 404, 301 then raise_config_error("Invalid base url or channel name")
      when 200, 201 then return response.status
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
      
Changes: #{shorten_url(payload['compare'])}
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
    at          = Time.parse(c['timestamp'])
    description = c['message'][0 .. 60]
    commit_message = <<-EOC
(#{i}) "#{description}"  - #{c['author']['name']}
       #{shorten_url(c['url'])} - #{at.strftime(@time_format)} - #{at.strftime(@time_format)}
EOC
  end

  def commit_detail_message(c, i)
    at             = Time.parse(c['timestamp'])
    added          = c['added'].join(' ')
    removed        = c['removed'].join(' ')
    modified       = c['modified'].join(' ')
    commit_message = <<-EOC
(#{i}) #{c['author']['name']} <#{c['author']['email']}>
#{shorten_url(c['url'])} - #{at.strftime(@time_format)}
Files added: #{added}
Files removed: #{removed}
Files modified: #{modified}

#{c['message']}  
-------------------------------------------------------------------------------
    
EOC
  end

end
