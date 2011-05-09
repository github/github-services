module TargetProcess
  class Users
    include HTTParty
    format :xml

    def initialize(u, p, b)
      @auth = {:username => u, :password => p}
      self.base_uri = b
    end

    def gather_all(acid)
      self.class.get('/api/v1/Users/?acid='+acid,{:basic_auth => @auth})
    end
  end

  class Context
    include HTTParty
    format :xml

    def initialize(u, p, b)
      @auth = {:username => u, :password => p}
      self.base_uri = b
    end

    def get_by_project(id)
      self.class.get('/api/v1/Context?ids='+id,{:basic_auth => @auth})
    end
  end

  class EntityState
    include HTTParty
    format :xml

    def initialize(u, p, b)
      @auth = {:username => u, :password => p}
      self.base_uri = b
    end

    def gather_all(acid)
      self.class.get('/api/v1/EntityState?acid='+acid,{:basic_auth => @auth})
    end
  end

  class Remote
    def initialize(data={})
      # required fot connection
      @base_url, @username, @password, @project_id = data['base_url'], data['username'], data['password'], data['project_id']
      # check if all the variables are initialized from service params
      [@base_url, @username, @password, @project_id].each{|var| raise GitHub::ServiceConfigurationError.new("Missing configuration: #{var}") if var.to_s.empty? }
      # delete last slash in the string
      correct_uri = @base_url.gsub(/\/$/, '')
      @uri = URI.parse(correct_uri)
      get_context_and_users
    end

    def process_commits(payload)
      payload["commits"].each{
          |commit| process_commit(commit)
      }
    end


private
    def process_commit(commit)
      author = find_user_by_email(commit["author"]["email"])
      return if author.nil?
      commit["message"].each{ |commit_line|
        bug_id = commit_line[/( |^)#(\d+):.+/, 1]
        next if bug_id.nil?
        command = commit_line[/( |^)#\d+:(.+)/, 1].strip
        next if command.nil?
        get_state_data
        execute_command(author, bug_id, command, commit)
      }
    end

    def execute_command(author, bug_id, command, commit)
      @states.each do |e|
        next if e.Name != command
        @soap_client = Savon::Client.new(@uri.path + "/Services/BugService.asmx?WSDL") do
          wsse.credentials @username, @password
        end
        response = @soap_client.request :update do
          soap.body = {
            :BugID => bug_id,
            :LastEditorId => author.UserID,
            :EntityStateID => e.Id
          }
        end
        if response.html.success?
          # Add the comment
          @soap_client.request :AddCommentToBug do
            soap.body = {
              :BugID => bug_id,
              :OwnerID => author.UserID,
              :Description => commit["Message"]
            }
          end
        end
      end
    end

    def find_user_by_email(email)
      @users.each do |u|
        if u.Email == email
          return u.Id
        end
      end
      nil
    end

    def get_context_and_users()
      @context_data = Context.new(@username,@password,@base_url).get_by_project(@project_id)
      @users = Users.new(@username,@password,@base_url).gather_all(@context_data.Acid)
    end

    def get_state_data()
      states = EntityState.new(@username,@password,@base_url).gather_all(@context_data.Acid)
      @states = {}
      states.each do |s|
        if s.EntityType == "Bug"
          @states.merge(s)
        end
      end
    end
  end
end

service :target_process do |data, payload|
  begin
    TargetProcess::Remote.new(data).process_commits(payload)
  rescue => e
    case e.to_s
      when /\((?:403|401|422)\)/ then raise GitHub::ServiceConfigurationError, "Invalid credentials"
      when /\((?:404|301|302)\)/ then raise GitHub::ServiceConfigurationError, "Invalid TargetProcess URL"
      else raise
    end
  end
end
