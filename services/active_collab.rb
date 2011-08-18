require 'bigdecimal'
require 'date'
require 'jcode'
require 'net/http'
require 'net/https'
require 'time'
require 'rexml/document'
require 'uri'

class Service::ActiveCollab < Service
  string  :url, :token, :project_id, :milestone_id, :category_id

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
      status = "[#{repository}] #{tiny_url} #{author['name']} - #{commit['message']}"
      statuses << status
    end

    build_message = ""

    statuses.each do |status|
      build_message = "#{build_message}#{status}\n"
    end

    @req = Net::HTTP::Post.new("#{url.path}?path_info=projects/#{data['project_id']}/discussions/add&token=#{data['token']}", headers);
    @req.set_form_data(params(push_message, build_message))
    @response = Net::HTTP.new(url.host, url.port).start { |http| http.request(@req) }
  end

  def headers
    {
      "Accept"  =>  "application/xml"
    }
  end

  def url
    URI.parse(data['url'])
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

  attr_reader :response
end
