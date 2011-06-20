require 'savon'

module TargetProcess
  class Context
    include HTTParty
    format :xml

    def initialize(u, p, b)
      @auth = {:username => u, :password => p}
      @base_uri = b
    end

    def get_by_project(id)
      self.class.get('%s/api/v1/Context/?ids=%s' % [@base_uri , id],{:basic_auth => @auth})
    end
  end

  class Bugs
    include HTTParty
    format :xml

    def initialize(u, p, b)
      @auth = {:username => u, :password => p}
      @base_uri = b
    end

    def gather_all(acid)
      self.class.get('%s/api/v1/Bugs/?acid=%s&include=[Name,EntityState,Assignments[GeneralUser[Login,Email]]]' % [@base_uri, acid],{:basic_auth => @auth})
    end

    def gather_by_id(id,acid)
      self.class.get('%s/api/v1/Bugs/%s?acid=%s&include=[Name,EntityState,Assignments[GeneralUser[Login,Email]]]' % [@base_uri, id, acid],{:basic_auth => @auth})
    end
  end


  class Remote
    def initialize(data={})
      # required fot connection
      @base_url, @username, @password, @project_id = data['base_url'], data['username'], data['password'], data['project_id']
      # check if all the variables are initialized from service params
      [@base_url, @username, @password, @project_id].each{|var| raise GitHub::ServiceConfigurationError.new("Missing configuration: #{var}") if var.to_s.empty? }
      # delete last slash in the string
      @base_url = @base_url.gsub(/\/$/, '')
      # Disable all the insane output from Savon/HTTPI
      Savon.configure do |c|
        c.log = false
        c.log_level = :info
      end
      HTTPI.log = false
      get_context_data
      get_state_data
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
	parts = commit_line.match(/(\s|^)#(\d+):(.+)\s?(.*)/)
	next if parts.nil?
	bug_id = parts[2].strip
        next if bug_id.nil? or bug_id.length == 0
        command = parts[3].strip
        next if command.nil? or command.length == 0
        execute_command(author, bug_id, command, commit)
      }
    end

    def execute_command(author, bug_id, command, commit)
      bug = Bugs.new(@username,@password,@base_url).gather_by_id(bug_id, @context_data['Context']['Acid']).parsed_response['Bug']
      return if bug.nil?
      state = get_state_id_by_name(command)
      return if state.nil?
      @soap_client = Savon::Client.new(@base_url + "/Services/BugService.asmx?WSDL")
      @soap_client.wsse.credentials @username, @password
      response = @soap_client.request :wsdl, :change_state do
        soap.body = {
          :bugID => bug_id,
          :entityStateID => state
        }
      end
      # Add the comment
      @soap_client.request :wsdl, :add_comment_to_bug do
        soap.body = {
          :bugID => bug_id,
          :comment => {
            "OwnerID" => author[:user_id],
            "GeneralID" => bug_id,
            "Description" => commit["message"]
          }
        }
      end
    end

    def find_user_by_email(email)
      @soap_client = Savon::Client.new(@base_url + "/Services/UserService.asmx?WSDL")
      @soap_client.wsse.credentials @username, @password
      response = @soap_client.request :wsdl, :retrieve do |soap|
        soap.body = { :hql => "from User where Email = '#{email}'", :parameters => { :string => email } }
      end
      user_info = response.to_hash[:retrieve_response][:retrieve_result]
      user_info[:user_dto] rescue nil
    end

    def get_context_data()
      @context_data = Context.new(@username,@password,@base_url).get_by_project(@project_id).parsed_response
    end

    def get_state_data()
      @soap_client = Savon::Client.new(@base_url + "/Services/ProcessService.asmx?WSDL")
      @soap_client.wsse.credentials @username, @password
      response = @soap_client.request :wsdl, :retrieve_entity_states_for_process do |soap|
	soap.body = { :processID => @context_data['Context']['Processes']['ProcessInfo']['Id'] }
      end
      state_info = response.to_hash[:retrieve_entity_states_for_process_response][:retrieve_entity_states_for_process_result][:entity_state_dto]
      @states = []
      state_info.each do |v|
	if v[:entity_type_name] == 'Tp.BusinessObjects.Bug'
	  # Add this to our collection of possible states
	  @states.push(v)
	end
      end
    end

    def get_state_id_by_name(state_name)
      @states.each do |s|
	if s[:name].capitalize == state_name.capitalize
	  return s[:entity_state_id]
	end
      end
      nil
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

