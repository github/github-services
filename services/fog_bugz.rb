service :fog_bugz do |data, payload|
  
  repository  = payload['repository']['name']
  branch      = payload['ref'].split('/').last
  before      = payload['before']   
  
  payload['commits'].each do |commit|
    commit_id = commit['id']
    message   = commit["message"]
    files     = commit["removed"] | commit["added"] | commit["modified"]
    
    # look for a bug id in each line of the commit message
    bug_list = []
    message.split("\n").each do |line|
      if (line =~ /\s*Bug[zs]*\s*IDs*\s*[#:; ]+((\d+[ ,:;#]*)+)/i)
        bug_list << $1.to_i
      end
    end
    
    # for each found bugzid, submit the files to fogbugz.
    bug_list.each do |fb_bugzid|
      files.each do |f|
        fb_repo = CGI.escape("#{repository}")
        fb_r1 = CGI.escape("#{before}")
        fb_r2 = CGI.escape("#{commit_id}")
        fb_file = CGI.escape("#{branch}/#{f}")
        
        # build the GET request, and send it to fogbugz
		    if data['fb_version'] == '7.0'
          fb_url = "#{data['cvssubmit_url']}?ixBug=#{fb_bugzid}&sFile=#{fb_file}&sPrev=#{fb_r1}&sNew=#{fb_r2}&ixRepository=#{data['fb_repoid']}"
		    else
          # FogBugz 6.1
          fb_url = "#{data['cvssubmit_url']}?ixBug=#{fb_bugzid}&sRepo=#{fb_repo}&sFile=#{fb_file}&sPrev=#{fb_r1}&sNew=#{fb_r2}"
        end
        url = URI.parse(fb_url)
        conn = Net::HTTP.new(url.host, url.port)
        conn.use_ssl = url.scheme == "https"
        conn.verify_mode = OpenSSL::SSL::VERIFY_NONE
        conn.start do |http| 
          http.get(url.path + '?' + url.query)
        end

      end
    end
  end
end
