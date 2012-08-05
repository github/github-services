require "net/https"
require "uri"

class RedmineUpdater

  def initialize(redmine_url, api_key)
    @redmine_url = redmine_url
    @api_key     = api_key
    uri = URI.parse(@redmine_url)
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end


  # send the commit notification to be added into redmine issue notes
  def notify_about_commit(issue_no, commit)
    request = Net::HTTP::Put.new("/issues/#{issue_no}.json")
    request['Content-Type']='application/json'
    request['X-Redmine-API-Key']=@api_key
    request.set_form_data({"issue[notes]" => commit_text(commit)})
    res= @http.request(request)
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

class Service::RedmineIssueUpdate < Service
  string :redmine_url, :api_key
  white_list :redmine_url

  def receive_push

    redmine_updater = RedmineUpdater.new(data['redmine_url'], data['api_key'])

  	payload['commits'].each do |commit|
      message = commit['message'].clone

      #Extract issue IDs and send update to the related issues
      while !(id= message[/#(\d)+/]).nil? do 
        message.gsub!(id,'')
        redmine_updater.notify_about_commit(id.gsub('#',''), commit)
      end
    end   
  end
end

