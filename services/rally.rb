require 'time'

class Service::Rally < Service
  string   :server, :username, :workspace, :repository
  password :password

  attr_accessor :wksp_ref, :repo_ref, :user_cache, :chgset_uri
  attr_reader   :art_type, :branch, :artifact_detector

  def receive_push
    server     = data['server']
    username   = data['username']
    password   = data['password']
    workspace  = data['workspace']
    @branch    = payload['ref'].split('/')[-1]  # most of the time it'll be refs/heads/master ==> master
    repo       = payload['repository']['name']
    repo_owner = payload['repository']['owner']['name']
    @chgset_uri = 'http://github.com/%s/%s' % [repo_owner, repo] 
    
    http.ssl[:verify] = false
    if server =~ /^https?:\/\//   # if they have http:// or https://, leave server value unchanged
      http.url_prefix = "#{server}/slm/webservice/1.29"
    else
      server = "#{server}.rallydev.com" if server !~ /\./ # leave unchanged if '.' in server
      http.url_prefix = "https://#{server}/slm/webservice/1.29"
    end
    http.basic_auth(username, password)
    http.headers['Content-Type'] = 'application/json'
    http.headers['X-RallyIntegrationVendor']  = 'Rally'
    http.headers['X-RallyIntegrationName']    = 'GitHub-Service'
    http.headers['X-RallyIntegrationVersion'] = '1.0'

    @wksp_ref = validateWorkspace(workspace)
    @repo_ref = getOrCreateRepo(repo, repo_owner)

    @art_type = { 'D' => 'defect', 'DE' => 'defect', 'DS' => 'defectsuite', 
                 'TA' => 'task',   'TC' => 'testcase',
                  'S' => 'hierarchicalrequirement', 
                 'US' => 'hierarchicalrequirement'
                }
    formatted_id_pattern = '^(%s)\d+[\.:;]?$' % @art_type.keys.join('|') # '^(D|DE|DS|TA|TC|S|US)\d+[\.:;]?$'
    @artifact_detector = Regexp.compile(formatted_id_pattern)

    @user_cache = {}
    payload['commits'].each do |commit|
      artifact_refs = snarfArtifacts(commit['message'])
      addChangeset(commit, artifact_refs)
    end
  end

  def addChangeset(commit, artifact_refs)
      author = commit['author']['email']
      if !@user_cache.has_key?(author)
        user = rallyQuery('User', 'Name,UserName', 'UserName = "%s"' % [author])
        user_ref = ""
        user_ref = itemRef(user) unless user.nil?
        @user_cache[author] = user_ref
      end
      user_ref = @user_cache[author]
      message = commit['message']
      message = message[0..3999] unless message.size <= 4000
      changeset = { 'SCMRepository'   => @repo_ref,
                    'Revision'        => commit['id'],
                    'Author'          => user_ref,
                    'CommitTimestamp' => Time.iso8601(commit['timestamp']).strftime("%FT%H:%M:%S.00Z"),
                    'Uri'             => @chgset_uri,
                    'Artifacts'       => artifact_refs # [{'_ref' => 'defect/1324.js'}, {}...]
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
          change['Uri'] = '%s/blob/%s/%s' % [@chgset_uri, @branch, change['PathAndFilename']]
          chg_item = rallyCreate('Change', change)
      end
  end

  def validateWorkspace(workspace)
      all_your_workspaces = rallyWorkspaces()
      target_workspace = all_your_workspaces.select {|wksp| wksp['Name'] == workspace and wksp['State'] != 'Closed'}
      if target_workspace.length != 1
          problem = 'Config Error: target workspace: %s not available in list of workspaces associated with your credentials' % [workspace] 
          raise_config_error(problem)
      end
      return itemRef(target_workspace[0])
  end

  def getOrCreateRepo(repo, repo_owner)
      repo_item = rallyQuery('SCMRepository', 'Name', 'Name = "%s"' % repo)
      return itemRef(repo_item) unless repo_item.nil?
      repo_info = { 'Workspace' => @wksp_ref, 'Name' => repo, 'SCMType' => 'GitHub',
                    'Description' => 'GitHub-Service push changesets',
                    'Uri' => 'http://github.com/%s/%s' % [repo_owner, repo] 
                  }
      repo_item = rallyCreate('SCMRepository', repo_info)
      return itemRef(repo_item)
  end

  def itemRef(item) ref = item['_ref'].split('/')[-2..-1].join('/')[0..-4] end

  def rallyWorkspaces()
      response = @http.get('Subscription.js?fetch=Name,Workspaces,Workspace&pretty=true')
      raise_config_error('config error') unless response.success?
      qr =  JSON.parse(response.body)
      begin
          workspaces = qr['Subscription']['Workspaces']
      rescue Exception => ex
          raise_config_error('Config error: No such workspace for your credentials')
      end
      return workspaces
  end

  def rallyQuery(entity, fields, criteria)
      target_url = '%s.js?fetch=%s' % [entity.downcase, fields]
      target_url += '&query=(%s)' % [criteria] if criteria.length > 0
      target_url += '&workspace=%s' % [@wksp_ref]
      res = @http.get(target_url)
      raise StandardError("Config Error, #{entity} query failed") unless res.success?
      qr = JSON.parse(res.body)['QueryResult']
      item = qr['TotalResultCount'] > 0 ? qr['Results'][0] : nil
      return item
  end

  def rallyCreate(entity, data)
      create_url = "%s/create.js?workspace=%s" % [entity, @wksp_ref]
      payload = {"#{entity}" => data}
      res = @http.post(create_url, payload.to_json)
      raise_config_error("Unable to create the Rally #{entity} for #{data['Name']}") unless res.success?
      cr = JSON.parse(res.body)['CreateResult']
      item = cr['Object']
      return item
  end

  def snarfArtifacts(message)
      words = message.gsub(',', ' ').gsub('\r\n', '\n').gsub('\n', ' ').gsub('\t', ' ').split(' ')
      #rally_formatted_ids = words.select { |word| word =~ /^(D|DE|DS|TA|TC|S|US)\d+[\.:;]?$/ } 
      rally_formatted_ids = words.select { |word| @artifact_detector.match(word) } 
      artifacts = [] # actually, just the refs
      rally_formatted_ids.uniq.each do |fmtid|
          next unless fmtid =~ /^(([A-Z]{1,2})\d+)[\.:;]?$/
          fmtid, prefix  = $1, $2
          entity = @art_type[prefix]
          artifact = rallyQuery(entity, 'Name', 'FormattedID = "%s"' % fmtid)
          next if artifact.nil?
          art_ref = itemRef(artifact)
          artifacts << {'_ref' => art_ref}
      end
      return artifacts
  end

end
