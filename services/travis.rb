module Travis
  class ServiceHook
    attr_reader :data, :payload

    def initialize(data, payload)
      @data = data
      @payload = payload
    end

    def post
      Net::HTTP.post_form(travis_url, :payload => JSON.generate(payload))
    end

    def travis_url
      URI.parse("#{scheme}://#{user}:#{token}@#{domain}/builds")
    end

    def user
      if data['user'].to_s == ''
        payload['repository']['owner']['name']
      else
        data['user']
      end.strip
    end

    def token
      data['token'].strip
    end

    def scheme
       domain_parts.size == 1 ? 'http' : domain_parts.first
    end

    def domain
       domain_parts.last
    end

    protected

    def full_domain
      if data['domain'].to_s == ''
        'http://travis-ci.org'
      else
        data['domain']
      end.strip
    end

    def domain_parts
      full_domain.split('://')
    end
  end
end

service :travis do |data, payload|
  Travis::ServiceHook.new(data, payload).post
  nil
end

