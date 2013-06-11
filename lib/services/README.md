# Services

This is the directory that all Services go.  Creating a Service is
simple:

```ruby
class Service::MyService < Service
  def receive_push
  end
end
```

Inside the method, you can access the configuration data in a hash named
`data`, and the payload data in a Hash named `payload`.

Note: A service can respond to more than one event.

## Tip: Check configuration data early.

```ruby
class Service::MyService < Service
  def receive_push
    if data['username'].to_s.empty?
      raise_config_error "Needs a username"
    end
  end
end
```

## Tip: Use `http` helpers to make HTTP calls easily.

```ruby
class Service::MyService < Service
  def receive_push
    # Sets this basic auth info for every request.
    http.basic_auth(data['username'], data['password'])

    # Every request sends JSON.
    http.headers['Content-Type'] = 'application/json'

    # Uses this URL as a prefix for every request.
    http.url_prefix = "https://my-service.com/api"

    payload['commits'].each do |commit|

      # POST https://my-service.com/api/commits.json
      http_post "commits.json", commit.to_json

    end
  end
end
```

## Tip: Test your service like a bossk.

```ruby
class MyServiceTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/create.json" do |env|
      assert_equal 'my-service.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      assert_equal basic_auth("user", "pass"),
        env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service :push,
      {'username' => 'user', 'password' => 'pass'}, payload
    svc.receive_push
  end

  def service(*args)
    super Service::MyService, *args
  end
end
```

## Documentation

Each Service needs to have documentation aimed at end users in /docs.
See existing services for the format.
