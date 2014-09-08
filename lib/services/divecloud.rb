class Service::DiveCloud < Service::HttpPost
  title 'DiveCloud - Application Performance Testing'
  hook_name 'Github Plugin Service'

  string :plan_id
  password :api_key, :creds_pass
  boolean :random_timing
  white_list :plan_id, :random_timing

  url "https://divecloud.nouvola.com"
  logo_url "https://divecloud.nouvola.com/assets/logo.png"

 default_events :status

  maintained_by github: 'landrywj'
  supported_by  web: 'http://www.nouvola.com/contact',
                email: 'info@nouvola.com',
                twitter: '@NouvolaTech'


      def divecloud_api
        http(:url => "https://divecloud.nouvola.com") do |connection|
          connection.headers[:user_agent] = 'Github Agent'
          connection.request :url_encoded
          connection.response :logger
        end
      end

      def receive_status #run_test
        return unless payload['state'] == 'success'
        
        @plan_id = required_config_value('plan_id')
        @api_key = required_config_value('api_key')
        @creds_pass = config_value('creds_pass')
        @random_timing = config_value('random_timing')

        divecloud_api.post do |request|
          request.url "/api/v1/plans/#{@plan_id}/run"
          request.headers['Content-Type'] = 'application/json'
          request.headers['x-api'] = @api_key
          request.body = generate_json(:creds_pass => @creds_pass, :random_timing => @random_timing )
        end
      end


end
  