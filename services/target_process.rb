require 'savon'

module TargetProcess
  class Remote
    def initialize(data={})
      # required fot connection
      @base_url, @username, @password, @project_key = data['base_url'], data['username'], data['password'], data['project_key']
      # check if all the variables are initialized from service params
      [@base_url, @username, @password, @project_key].each{|var| raise GitHub::ServiceConfigurationError.new("Missing configuration: #{var}") if var.to_s.empty? }
      # delete last slash in the string
      @soap_path = @base_url.gsub(/\/$/,'') + "/Services/"
      @tp_client = Savon::Client.new()
      @tp_client.wsse.credentials @username, @password
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
        bug_id = commit_line[/( |^)#(\w+-\d+) /, 2]
        next if bug_id.nil?
        command = commit_line[/( |^)#\w+-\d+ (.+)/, 2].strip
        next if command.nil?
        get_state_data
        execute_command(author, bug_id, command, commit)
      }
    end

    def get_state_data()
      @tp_client.wsdl.document = @soap_path + 'ProjectService.asmx?WSDL'
      response = @tp_client.request :wsdl, "Retreive", :query => ["from Projects as p where p.IsActive = 1 and p.Abbreviation = '%s'" % @project_key]
      raise GitHub::ServiceConfigurationError.new("Cannot find project #{@project_key}, verify it is active and exists") if !response.html.success?
      process_id = response.to_hash.RetreiveResult.ProjectDTO.ProcessId
      @tp_client.wsdl.document = @soap_path + 'ProcessService.asmx?WSDL'
      response = @tp_client.request :wsdl, "RetrieveEntityStatesForProcess", :processID => process_id
      raise GitHub::ServiceConfigurationError.new("Cannot retreive state data for process ID #{process_id}") if !response.html.success?
      @state_data = response.to_hash
    end

    def execute_command(author, bug_id, command, commit)
      return if bug = find_bug_by_id(bug_id) == false
      @state_data.RetrieveEntityStatesForProcessResult.each do |e|
        next if e.Name != command
        @tp_client.wsdl.document = @soap_path + 'BugService.asmx?WSDL'
        response = @tp_client.request :update do
          soap.body = {
            :BugID => bug.BugID,
            :LastEditorId => author.UserID,
            :EntityStateID => e.EntityStateID
          }
        end
        if response.html.success?
          # Add the comment
          @tp_client.request :AddCommentToBug do
            soap.body = {
              :BugID => bug.BugID,
              :OwnerID => author.UserID,
              :Description => commit["Message"]
            }
          end
        end
      end
    end

    def find_user_by_email(email)
      @tp_client.wsdl.document = @soap_path + 'UserService.asmx?WSDL'
      response = @tp_client.request :retrieve do
	soap.body = ["<query>from Users where active = 1 and email = '%s'</query>" % email]
	soap.input = ["Retrieve", {"xmlns" => "http://targetprocess.com/"}]
      end
      begin
        if !response.http.success? 
	  nil
        else
	  response.to_hash.RetreiveResult.UserDTO
	end
      rescue
	nil
      end
    end

    def find_bug_by_id(bug_id)
      @tp_client.wsdl.document = @soap_path + 'BugService.asmx?WSDL'
      response = @tp_client.request :wsdl, "GetByID", :id => bug_id
      begin
        if !response.http.success? 
          false
        else
          response.to_hash
        end
      rescue 
        false
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
