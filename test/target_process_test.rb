require File.expand_path('../helper', __FILE__)

class TargetProcessTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/api/v1/Context" do |env|
      assert_equal 'foo.com', env[:url].host
      assert_equal '1000101', env[:params]['ids']
      assert_equal basic_auth('uz0r', 'p455w0rd'), env[:request_headers]['authorization']
      [200, {}, '<Context Acid="ZOMG"><Processes><ProcessInfo Id="OMGWTFBBQ" Name="U mad bro"></ProcessInfo></Processes></Context>']
    end

    @stubs.get "/api/v1/Users?include=%5BEmail%5D" do |env|
      assert_equal basic_auth('uz0r', 'p455w0rd'), env[:request_headers]['authorization']
      [200, {}, '<Items><User Id="31337"><Email>jonnyfunfun@gmail.com</Email></User><User Id="3"><Email>foobar@snafu.com</Email></User></Items>']
    end

    @stubs.get "/api/v1/Processes/OMGWTFBBQ/EntityStates" do |env|
      assert_equal 'ZOMG', env[:params]['acid']
      assert_equal basic_auth('uz0r', 'p455w0rd'), env[:request_headers]['authorization']
      [200, {}, '<Items><EntityState Name="fubar" Id="21"/><EntityState Name="not me" Id="0"/></Items>']
    end

    @stubs.get "/api/v1/Assignables/1783?acid=ZOMG&include=%5BEntityType%5D" do |env|
      assert_equal '[EntityType]', env[:params]['include']
      assert_equal 'ZOMG', env[:params]['acid']
      assert_equal basic_auth('uz0r', 'p455w0rd'), env[:request_headers]['authorization']
      [200, {}, '<Assignable Id="1783"><EntityType Id="42" Name="Bug"/></Assignable>']
    end

    @stubs.post "/api/v1/Comments" do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal "{General: {Id: 1783}, Description: 'stuff #1783:fubar', Owner: {Id: 31337}}", env[:body]
      assert_equal basic_auth('uz0r', 'p455w0rd'), env[:request_headers]['authorization']
      [201, {}, '']
    end

    @stubs.post "/api/v1/Bugs" do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal '{Id: 1783, EntityState: {Id: 21}}', env[:body]
      assert_equal basic_auth('uz0r', 'p455w0rd'), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service(
      {'base_url' => 'http://foo.com/', 'username' => 'uz0r', 'password' => 'p455w0rd',
       'project_id' => '1000101'},
        payload)
    svc.receive_push
  end

  def service(*args)
    super Service::TargetProcess, *args
  end

  def payload
      # Stripped down with only the information we need
      {
        "commits" => [
          {
            "message"   => "stuff #1783:fubar",
            "author"    => { "name" => "Jonathan Enzinna", "email" => "jonnyfunfun@gmail.com" }
          }
        ]
      }
  end
end
