class Service::PagesTwitter < Service
  string  :token, :secret, :domain

  def receive_push
    
    # 
    # We need to run this hook only for two cases:
    #   1. push to <repository_owner>.github.com/master
    #   2. push to <repository_name>/gh-pages
    #

    #
    # Checking branches from the list above 
    #

    branch = payload['ref'].split('/').last # Name of the pushed branch
    repository = payload['repository']['name']  # Name of the pushed repository
    if branch != 'gh-pages'    
      owner_name = payload['repository']['owner']['name'] # Name of repository owner
      if !(branch == "master" && repository == owner_name + ".github.com")
        # If we are here the branch doesn't need this hook
        # 
        # Exit hook
        # 
        return 1
      end
    end

    #
    # domain is custom domain of github pages taken from CNAME file or 
    # <repository_owner>.github.com
    #
    
    domain = data['domain']
    
    #
    # Now we need to check added files in the each commit
    # If files haven't been added then do nothing,
    # otherwise build the status for each new post.
    # 
    # Match string is modified regular expression from jekyll/lib/jekyll/site.rb
    #
    
    statuses = []
    
    payload['commits'].each do |commit|
      if commit['message'][0..5].downcase == "[post]"
        commit['added'].each do |file|
          blocks = file.match(/^(.+\/)*(\d+)-(\d+)-(\d+)-(.*)(\.[^.]+)$/)
          if blocks
            year,month,day,postname = *(blocks.values_at(-5,-4,-3,-2))
            post_anounce = commit['message'][6..-1]
            tuny_url = shorten_url("#{domain_way(branch, repository, domain)}/#{url_path(year,month,day,postname)}")
            status = tuny_url + " " + post_anounce
            status.length >= 140 ? statuses << status[0..136] + '...' : statuses << status
          else
            # Added file isn't post. Do nothing
          end
        end
      end
    end
 
    statuses.each do |status|
      post(status)
    end
    
  end
  
  def domain_way(branch, repository, domain)
    if branch == 'master'
      return "#{domain}"
    end
    if branch == 'gh-pages'
      return "#{domain}/#{repository}"
    end
  end
  
  def url_path(year,month,day,postname)
    "#{year}/#{month}/#{day}/#{postname}.html"
  end
  
  #
  # The functions below are copied from Twitter service
  #
  
  def post(status)
    params = { 'status' => status, 'source' => 'github' }

    access_token = ::OAuth::AccessToken.new(consumer, data['token'], data['secret'])
    consumer.request(:post, "/1/statuses/update.json",
                     access_token, { :scheme => :query_string }, params)
  end

  def consumer_key
    secrets['twitter']['key']
  end

  def consumer_secret
    secrets['twitter']['secret']
  end

  def consumer
    @consumer ||= ::OAuth::Consumer.new(consumer_key, consumer_secret,
                                        {:site => "http://api.twitter.com"})
  end
  
end
