class Service::DiveCloud < Service::HttpPost
  title 'DiveCloud - Application Performance Testing'
  url "https://divecloud.nouvola.com"
  logo_url "http://www.nouvola.com/wp-content/uploads/2014/01/nouvola_logo_reg1.png"
  
  maintained_by github: 'prossaro'
  supported_by  web: 'http://www.nouvola.com/contact',
                email: 'support@nouvola.com',
                twitter: '@NouvolaTech'

    default_events :deployment_status
    string :plan_id
    password :api_key, :creds_pass
    boolean :random_timing
    white_list :plan_id, :random_timing

  
  def receive_deployment_status
    #Only run performance test after successful deployment
    return unless payload['status'] == "success"

    #Sanitize instances of data[:params]
    @plan_id = required_config_value('plan_id')
    @api_key = required_config_value('api_key')
    @creds_pass = config_value('creds_pass')
    @random_timing = config_value('random_timing')

    #Connect to api on port 443
     http.url_prefix = "https://divecloud.nouvola.com"
    
    #Run test
    http.post do |request|
       request.url "/api/v1/plans/#{@plan_id}/run"
       request.headers['Content-Type'] = 'application/json'
       request.headers['x-api'] = @api_key
       request.headers['user_agent'] = 'Github Agent'
       request.body = generate_json(:creds_pass => @creds_pass, :random_timing => @random_timing )
     end
  end

end 