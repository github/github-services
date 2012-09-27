require File.expand_path('../helper', __FILE__)

class WorkmarketTest < Service::TestCase
	def setup
		@stubs = Faraday::Adapter::Test::Stubs.new
	end

	def test_push
		@stubs.post "/api/v1/authorization/request" do |env|
			assert_equal 'application/json', env[:request_headers]['Content-Type']
			assert_equal 'www.workmarket.com', env[:url].host
			[200, {}, '']
		end

		svc = service(
			{'token' => 't', 'secret' => 's'},
			payload
		)
		svc.receive_push
	end

	def service(*args)
		super Service::Workmarket, *args
	end
end