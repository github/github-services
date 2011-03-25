#require File.expand_path('../github-services', __FILE__)
#require "/home/user/git-services/github-services/github-services.rb"
#require "/usr/lib/ruby/1.8/net/http.rb"
#require "rexml/document"
#require "cgi"

module YouTrack

  class Remote
    def initialize(data={})
      # required fot connection
      @base_url, @username, @password, @commiters = data['base_url'], data['username'], data['password'], data['commiters']
      # check if all the variables are initialized from service params
      [@base_url, @username, @password, @commiters].each{|var| raise GitHub::ServiceConfigurationError.new("Missing configuration: #{var}") if var.to_s.empty? }
      # delete last slash in the string
      correct_uri = @base_url.gsub(/\/$/, '')
      @uri = URI.parse(correct_uri)
      @rest_path = @uri.path + "/rest"
      @conn = Net::HTTP.new(@uri.host, @uri.port)
    end

    def process_commits(payload)
      login
      payload["commits"].each{
          |commit| process_commit(commit)
      }
    end

    def login()
      @conn.start do |http|
        req = Net::HTTP::Post.new(@rest_path + "/user/login?login=" + @username + "&password=" + @password, {"Content-Length" => "0"})
        resp = http.request(req)
        resp.value
        @headers = {"Cookie" => resp["set-cookie"], "Cache-Control"=> "no-cache"}
      end
    end

    def execute_command(author, issue_id, command)
      @conn.start do |http|
        req = Net::HTTP::Post.new(@rest_path + "/issue/" + issue_id + "/execute?command=" + command + "&runAs=" + author, @headers)
        resp = http.request(req)
        resp.value
      end
    end

    private
    def process_commit(commit)
      author = find_user_by_email(commit["author"]["email"])
      return if author.nil?
      commit["message"].each{ |commit_line|
        issue_id = commit_line[/( |^)#(\w+-\d+) /, 2]
        next if issue_id.nil?
        command = commit_line[/( |^)#\w+-\d+ (.+)/, 2].strip
        command = "Fixed" if command.nil?
        execute_command(author, issue_id, command)
      }
    end

    def find_user_by_email(email)
      counter = 0
      found_user = nil
      while true
        body = ""
        @conn.start do |http|
          req = Net::HTTP::Get.new(@rest_path + "/admin/user?q" +email + "&group="+CGI.escape(@commiters) +
                                       "&start=#{counter}", @headers)
          resp = http.request(req)
          resp.value
          body = resp.body
        end
        xml_body = REXML::Document.new(body)
        xml_body.root.each_element do |user_ref|
          @conn.start do |http|
            req = Net::HTTP::Get.new(@rest_path + "/admin/user/" + user_ref.attributes["login"], @headers)
            resp = http.request(req)
            resp.value
            if REXML::Document.new(resp.body).root.attributes["email"] == email
              return if !found_user.nil?
              found_user = user_ref.attributes["login"]
            end
          end
        end
        return found_user if xml_body.root.elements.size < 10
        counter += 10
      end

    end

  end
end

service :youtrack do |data, payload|
  #include YouTrack
  begin
    YouTrack::Remote.new(data).process_commits(payload)
  rescue => e
    case e.to_s
      when /\((?:403|401|422)\)/ then raise GitHub::ServiceConfigurationError, "Invalid credentials"
      when /\((?:404|301|302)\)/ then raise GitHub::ServiceConfigurationError, "Invalid YouTrack URL"
      else raise
    end
  end
end
