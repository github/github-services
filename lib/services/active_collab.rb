require 'bigdecimal'
require 'date'
require 'jcode' if RUBY_VERSION < '1.9'
require 'net/http'
require 'net/https'
require 'time'
require 'rexml/document'
require 'uri'

class Service::ActiveCollab < Service
  string  :url, :project_id, :milestone_id, :category_id
  password :token
  white_list :url, :project_id, :milestone_id, :category_id

  def receive_push
    if data['url'].to_s.empty?
      raise_config_error "Need an activeCollab Url"
    end
    if data['token'].to_s.empty?
      raise_config_error "Need an API Token"
    end
    if data['project_id'].to_s.empty?
      raise_config_error "Need a Project ID"
    end

    statuses   = [ ]
    repository = payload['repository']['name']

    push_message = "New Commits made in #{payload['pusher']['name']} / #{repository}"

    payload['commits'].each do |commit|
      author = commit['author'] || {}
      tiny_url = shorten_url(commit['url'])
      statuses << "[#{repository}] #{tiny_url} #{author['name']} - #{commit['message']}"
    end

    build_message = statuses * "\n"

    http.url_prefix = data['url']
    http.headers['Accept'] = 'application/xml'

    http.post do |req|
      req.params['path_info'] = "projects/#{data['project_id']}/discussions/add"
      req.params['token']     = data['token']
      req.body = params(push_message, build_message)
    end
  end

  def params(name, message)
    {
      "submitted" => "submitted",
      "discussion[name]" => "#{name}",
      "discussion[body]" => "#{message}",
      "discussion[milestone_id]" => data['milestone_id'],
      "discussion[parent_id]" => data['category_id'],
      "discussion[visibility]" => 1,
    }
  end
end
