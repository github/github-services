require File.expand_path('../helper', __FILE__)

class BeeminderTest < Service::TestCase
	def setup
		@stubs = Faraday::Adapter::Test::Stubs.new
	end

	def test_push
		svc = service :push,
		{'username' => 'mushroomman', 'goal_slug' => 'test', 'auth_token' => 'pmcyHoJFzqYNiRefmtD9'}, payload

		url = "https://www.beeminder.com/api/v1/users/"
		
		@stubs.post url do |env|
			assert_equal 'https', env[:url].scheme
			assert_equal 'beeminder.com', env[:url].host
			[200, {}, '']
		end

		svc.receive_push
	end

	def service(*args)
		super Service::Beeminder, *args
	end
end
