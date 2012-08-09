require "net/https"
require "uri"

class Service::Redmine < Service
  string :address, :project, :api_key
  boolean :fetch_github_commits
  boolean :update_redmine_issues_about_commits
  white_list :address, :project

  def receive_push

    if fetch_github_commits_enabled?
      http.ssl[:verify] = false
      http.url_prefix = data['address']
      http_get "sys/fetch_changesets" do |req|
        req.params['key'] = data['api_key']
        req.params['id']  = data['project']
      end
    end

    if update_issues_enabled?
      begin
        # check configurations first
        check_configuration_options(data)

        redmine_updater = RedmineUpdater.new(data['address'], data['api_key'])

        payload['commits'].each do |commit|
          message = commit['message'].clone

          #Extract issue IDs and send update to the related issues
          while !(id= message[/#(\d)+/]).nil? do 
            message.gsub!(id,'')
            redmine_updater.notify_about_commit(id.gsub('#',''), commit)
          end
        end
        return true   
      rescue SocketError => se
        return false
      rescue Exception => e
        return false
      end
    end
  end

  private
  def check_configuration_options(data)
    raise_config_error 'Redmine url must be set' if data['address'].blank?
    raise_config_error 'API key is required' if data['api_key'].blank?   
  end

  def fetch_github_commits_enabled?
    data['fetch_github_commits']
  end

  def update_issues_enabled?
    data['update_redmine_issues_about_commits']
  end

end

# RedmineUpdater class that notifies the redmine related issue about the commit
#===============================================================================
class RedmineUpdater

  def initialize(redmine_url, api_key)
    @redmine_url = redmine_url
    @api_key     = api_key
    uri = URI.parse(@redmine_url)
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true if @redmine_url.match(/https/)
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end


  # send the commit notification to be added into redmine issue notes
  def notify_about_commit(issue_no, commit)
    request = Net::HTTP::Put.new("/issues/#{issue_no}.json")
    request['Content-Type'] = 'application/json'
    request['X-Redmine-API-Key'] = @api_key
    request.set_form_data({"issue[notes]" => commit_text(commit)})
    res = @http.request(request)
    if res.code.to_i == 404 #Issue No not found
      raise Exception.new("Issue not found")
    end
  end

  private
    #Extract and buffer the needed commit information into one string
    def commit_text(commit) 
      gitsha   = commit['id']
      added    = commit['added'].map    { |f| ['A', f] }
      removed  = commit['removed'].map  { |f| ['R', f] }
      modified = commit['modified'].map { |f| ['M', f] }

      timestamp = Date.parse(commit['timestamp'])

      commit_author = "#{commit['author']['name']} <#{commit['author']['email']}>"

      text = align(<<-EOH)
        Commit: #{gitsha}
            #{commit['url']}
        Author: #{commit_author}
        Date:   #{timestamp} (#{timestamp.strftime('%a, %d %b %Y')})

      EOH

      text << align(<<-EOH)
        Log Message:
        -----------
        #{commit['message']}
      EOH

      text
    end

    def align(text, indent = '  ')
      margin = text[/\A\s+/].size
      text.gsub(/^\s{#{margin}}/, indent)
    end

end