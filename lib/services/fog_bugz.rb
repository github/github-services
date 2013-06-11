class Service::FogBugz < Service
  string :cvssubmit_url, :fb_repoid, :fb_version
  white_list :cvssubmit_url, :fb_repoid, :fb_version

  def receive_push
    if (fb_url = data['cvssubmit_url']).blank?
      raise_config_error "Invalid FogBugz URL"
    end

    # FIXME
    http.ssl[:verify] = false

    repository  = payload['repository']['name']
    branch      = branch_name
    before      = payload['before']

    payload['commits'].each do |commit|
      commit_id = commit['id']
      message   = commit["message"]
      files     = commit["removed"] | commit["added"] | commit["modified"]

      # look for a bug id in each line of the commit message
      bug_list = []
      message.split("\n").each do |line|
        # match variants of bugids or cases
        if (line =~ /\s*(?:Bug[zs]*\s*IDs*\s*|Case[s]*)[#:; ]+((\d+[ ,:;#]*)+)/i)
          bug_list << $1.to_i
        end
      end

      # for each found bugzid, submit the files to fogbugz.
      bug_list.each do |fb_bugzid|
        files.each do |f|
          # build the GET request, and send it to fogbugz
          params = {:ixBug => fb_bugzid, :sFile => "#{branch}/#{f}", :sPrev => before, :sNew => commit_id}
          if data['fb_version'] == '6'
            # FogBugz 6 created repositories automatically upon source checkin based on "sRepo"
            params[:sRepo] = repository
          else
            # FogBugz 7 and later requires you to create the repo in FogBugz and supply "ixRepository" here
            params[:ixRepository] = data['fb_repoid']
          end

          http_get fb_url, params
        end
      end
    end
  end
end
