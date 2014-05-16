require 'time'

class Service::Rally < Service
  string :server, :username, :workspace, :repository
  password :password
  white_list :server, :workspace, :repository

  attr_accessor :wksp_ref, :user_cache

  def receive_push
    server = data['server']
    username = data['username']
    password = data['password']
    workspace = data['workspace']
    scm_repository = data['repository']
    raise_config_error("No Server value specified") if server.nil? or server.strip.length == 0
    raise_config_error("No UserName value specified") if username.nil? or username.strip.length == 0
    raise_config_error("No Password value specified") if password.nil? or password.strip.length == 0
    raise_config_error("No Workspace value specified") if workspace.nil? or workspace.strip.length == 0
    branch = payload['ref'].split('/')[-1]  # most of the time it'll be refs/heads/master ==> master
    repo = payload['repository']['name']
    repo_uri = payload['repository']['url']

    http.ssl[:verify] = false
    if server =~ /^https?:\/\//   # if they have http:// or https://, leave server value unchanged
      http.url_prefix = "#{server}/slm/webservice/1.30"
    else
      server = "#{server}.rallydev.com" if server !~ /\./ # leave unchanged if '.' in server
      http.url_prefix = "https://#{server}/slm/webservice/1.30"
    end
    http.basic_auth(username, password)
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-RallyIntegrationVendor']  = 'Rally'
    http.headers['X-RallyIntegrationName']    = 'GitHub-Service'
    http.headers['X-RallyIntegrationVersion'] = '1.1'

    # create the repo in Rally if it doesn't already exist
    @wksp_ref = validateWorkspace(workspace)
    repo_ref = getOrCreateRepo(scm_repository, repo, repo_uri)
    @user_cache = {}
    payload['commits'].each do |commit|
      artifact_refs = snarfArtifacts(commit['message'])
      addChangeset(commit, repo_ref, artifact_refs, repo_uri, branch)
    end
  end

  def addChangeset(commit, repo_ref, artifact_refs, repo_uri, branch)
    author = commit['author']['email']
    if !@user_cache.has_key?(author)
      user = rallyQuery('User', 'Name,UserName', 'UserName = "%s"' % [author])
      user_ref = ""
      user_ref = itemRef(user) unless user.nil?
      @user_cache[author] = user_ref
    end

    user_ref = @user_cache[author]
    message = commit['message'][0..3999]  # message max size is 4000 characters
    changeset = {
      'SCMRepository' => repo_ref,
      'Revision' => commit['id'],
      'CommitTimestamp' => Time.iso8601(commit['timestamp']).strftime("%FT%H:%M:%S.00Z"),
      'Author' => user_ref,
      'Message' => message,
      'Uri' => '%s/commit/%s' % [repo_uri, commit['id']],
      'Artifacts' => artifact_refs # [{'_ref' => 'defect/1324.js'}, {}...]
    }
    changeset.delete('Author') if user_ref == ""

    begin
      changeset_item = rallyCreate('Changeset', changeset)
      chgset_ref = itemRef(changeset_item)
    rescue Faraday::Error => boom  # or some other sort of Faraday::Error::xxxError
      raise_config_error("Unable to create Rally Changeset")
      # changeset_item = nil
    end

    return if changeset_item.nil?

    # change has changeset_ref, Action, PathAndFilename, Uri
    changes = []
    commit['added'].each    { |add| changes << {'Action' => 'A', 'PathAndFilename' => add } }
    commit['modified'].each { |mod| changes << {'Action' => 'M', 'PathAndFilename' => mod } }
    commit['removed'].each  { |rem| changes << {'Action' => 'R', 'PathAndFilename' => rem } }
    changes.each do |change|
      change['Changeset'] = chgset_ref
      change['Uri'] = '%s/blob/%s/%s' % [repo_uri, branch, change['PathAndFilename']]
      chg_item = rallyCreate('Change', change)
    end
  end

  def validateWorkspace(workspace)
    all_your_workspaces = rallyWorkspaces()
    target_workspace = all_your_workspaces.select {|wksp| wksp['Name'] == workspace and wksp['State'] != 'Closed'}
    if target_workspace.length != 1
      problem = 'Config Error: target workspace %s not available in list of workspaces associated with your credentials' % [workspace]
      raise_config_error(problem)
    end

    return itemRef(target_workspace[0])
  end

  def getOrCreateRepo(scm_repository, repo, repo_uri)
    scm_repository = repo if (scm_repository.nil? or scm_repository == "")
    repo_item = rallyQuery('SCMRepository', 'Name', 'Name = "%s"' % scm_repository)
    return itemRef(repo_item) unless repo_item.nil?
    repo_info = {
      'Workspace' => @wksp_ref,
      'Name' => scm_repository,
      'SCMType' => 'GitHub',
      'Description' => 'GitHub-Service push Changesets',
      'Uri' => '%s' % [repo_uri]
    }
    repo_item = rallyCreate('SCMRepository', repo_info)

    return itemRef(repo_item)
  end

  def itemRef(item)
    ref = item['_ref'].split('/')[-2..-1].join('/')[0..-4]
  end

  def rallyWorkspaces()
    response = @http.get('Subscription.js?fetch=Name,Workspaces,Workspace&pretty=true')
    raise_config_error('Config error: credentials not valid for Rally endpoint') if response.status == 401
    raise_config_error('Config error: unable to obtain your Rally subscription info') unless response.success?
    qr =  JSON.parse(response.body)
    begin
      workspaces = qr['Subscription']['Workspaces']
    rescue Exception => ex
      raise_config_error('Config error: no such workspace for your credentials')
    end

    return workspaces
  end

  def rallyQuery(entity, fields, criteria)
    target_url = '%s.js?fetch=%s' % [entity.downcase, fields]
    target_url += '&query=(%s)' % [criteria] if criteria.length > 0
    target_url += '&workspace=%s' % [@wksp_ref]
    res = @http.get(target_url)
    raise StandardError("Config Error: #{entity} query failed") unless res.success?
    qr = JSON.parse(res.body)['QueryResult']
    item = qr['TotalResultCount'] > 0 ? qr['Results'][0] : nil

    return item
  end

  def rallyCreate(entity, data)
    create_url = "%s/create.js?workspace=%s" % [entity, @wksp_ref]
    payload = {"#{entity}" => data}
    res = @http.post(create_url, generate_json(payload))
    raise_config_error("Unable to create the Rally #{entity} for #{data['Name']}") unless res.success?
    cr = JSON.parse(res.body)['CreateResult']
    item = cr['Object']

    return item
  end

  def snarfArtifacts(message)
    art_type = {
      'D' => 'defect',
      'DE' => 'defect',
      'DS' => 'defectsuite',
      'TA' => 'task',
      'TC' => 'testcase',
      'S' => 'hierarchicalrequirement',
      'US' => 'hierarchicalrequirement'
    }
    formatted_id_pattern = '^(%s)\d+[\.:;]?$' % art_type.keys.join('|') # '^(D|DE|DS|TA|TC|S|US)\d+[\.:;]?$'
    artifact_detector = Regexp.compile(formatted_id_pattern)
    words = message.gsub(',', ' ').gsub('\r\n', '\n').gsub('\n', ' ').gsub('\t', ' ').split(' ')
    rally_formatted_ids = words.select { |word| artifact_detector.match(word) }
    artifacts = [] # actually, just the refs
    rally_formatted_ids.uniq.each do |fmtid|
      next unless fmtid =~ /^(([A-Z]{1,2})\d+)[\.:;]?$/
      fmtid, prefix  = $1, $2
      entity = art_type[prefix]
      artifact = rallyQuery(entity, 'Name', 'FormattedID = "%s"' % fmtid)
      next if artifact.nil?
      art_ref = itemRef(artifact)
      artifacts << {'_ref' => art_ref}
    end

    return artifacts
  end
end
