class Service::TeamCity < Service
  string :base_url, :build_type_id, :branches
  boolean :full_branch_ref
  string :username
  password :password
  boolean :check_for_changes_only
  white_list :base_url, :build_type_id, :branches, :username, :full_branch_ref

  maintained_by :github => 'JetBrains'

  supported_by :web => 'http://confluence.jetbrains.com/display/TW/Feedback',
               :email => 'teamcity-support@jetbrains.com'

  def receive_push
    return if payload['deleted']

    check_for_changes_only = config_boolean_true?('check_for_changes_only')

    branches = data['branches'].to_s.split(/\s+/)
    ref = payload["ref"].to_s
    branch = config_boolean_true?('full_branch_ref') ? ref : ref.split("/", 3).last
    return unless branches.empty? || branches.include?(branch)

    # :(
    http.ssl[:verify] = false

    base_url = data['base_url'].to_s
    if base_url.empty?
      raise_config_error "No base url: #{base_url.inspect}"
    end

    http.headers['Content-Type'] = 'application/xml'
    http.url_prefix = base_url
    http.basic_auth data['username'].to_s, data['password'].to_s
    build_type_ids = data['build_type_id'].to_s
    build_type_ids.split(",").each do |build_type_id|

      res = perform_post_request(build_type_id, check_for_changes_only, branch: branch)

      # Hotfix for older TeamCity versions (older than 2017.1.1) where a GET is needed
      if res.status == 415 || res.status == 405
        res = perform_get_request(build_type_id, check_for_changes_only, branch: branch)
      end

      case res.status
        when 200..299
        when 403, 401, 422 then raise_config_error("Invalid credentials")
        when 404, 301, 302 then raise_config_error("Invalid TeamCity URL")
        else raise_config_error("HTTP: #{res.status}")
      end

    end
  rescue SocketError => e
    raise_config_error "Invalid TeamCity host name" if e.to_s =~ /getaddrinfo: Name or service not known/
    raise
  end

  # This is undocumented call. TODO: migrate to REST API (TC at least 8.0)
  def perform_post_request(build_type_id, check_for_changes_only, branch: nil)
    if check_for_changes_only
      http_post "httpAuth/app/rest/vcs-root-instances/checkingForChangesQueue?locator=buildType:#{build_type_id}"
    else
      http_post "httpAuth/app/rest/buildQueue", "<build branchName=\"#{branch}\"><buildType id=\"#{build_type_id}\"/></build>"
    end
  end

  # This is undocumented call. TODO: migrate to REST API (TC at least 8.0)
  def perform_get_request(build_type_id, check_for_changes_only, branch: nil)
    if check_for_changes_only
      http_get "httpAuth/action.html", :checkForChangesBuildType => build_type_id
    else
      http_get "httpAuth/action.html", :add2Queue => build_type_id, :branchName => branch
    end
  end
end
