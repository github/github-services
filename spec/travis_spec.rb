require 'github-services'

describe 'travis service hook' do
  it 'accepts data and payload as intializing arguments' do
    hook = Travis::ServiceHook.new(data, payload)
    hook.should_not be_nil
  end

  it 'can read the user from data' do
    hook = Travis::ServiceHook.new(data, payload)
    hook.user.should == "kronn"
  end

  it 'can read the token from data' do
    hook = Travis::ServiceHook.new(data, payload)
    hook.token.should == "5373dd4a3648b88fa9acb8e46ebc188a"
  end

  it 'can read the domain from data' do
    hook = Travis::ServiceHook.new(data, payload)
    hook.domain.should == "my-travis-ci.heroku.com"
  end

  it 'should keep a "https" scheme in the travis-url' do
    hook = Travis::ServiceHook.new(data.merge({'domain' => 'https://example.com'}), payload)
    hook.scheme.should == 'https'
  end

  it 'can construct the post-receive url to post to' do
    url = Travis::ServiceHook.new(data, payload).travis_url
    url.should be_a URI::HTTP
    url.to_s.should == 'http://kronn:5373dd4a3648b88fa9acb8e46ebc188a@my-travis-ci.heroku.com/builds'
  end

  it 'can post the payload to the travis_url' do
    # this is the call we need to do in order to mimick the standard post-receive hook
    Net::HTTP.stub!(:post_form).once.with(
      URI.parse('http://kronn:5373dd4a3648b88fa9acb8e46ebc188a@my-travis-ci.heroku.com/builds'),
      :payload => JSON.generate(payload)
    ).and_return(true)

    Travis::ServiceHook.new(data, payload).post.should equal true
  end

  context 'form values' do
    it 'strips whitespace from form values' do
      data = {
        'user' => 'kronn  ',
        'token' => '5373dd4a3648b88fa9acb8e46ebc188a  ',
        'domain' => 'my-travis-ci.heroku.com   '
      }

      hook = Travis::ServiceHook.new(data, payload)
      hook.user.should == 'kronn'
      hook.token.should == '5373dd4a3648b88fa9acb8e46ebc188a'
      hook.domain.should == 'my-travis-ci.heroku.com'
    end

    it 'handles blank strings without errors' do
      data = {
        'user' => '',
        'token' => '5373dd4a3648b88fa9acb8e46ebc188a',
        'domain' => ''
      }

      hook = Travis::ServiceHook.new(data, payload)
      hook.user.should == 'mojombo'
      hook.token.should == '5373dd4a3648b88fa9acb8e46ebc188a'
      hook.domain.should == 'travis-ci.org'
      hook.scheme.should == 'http'
    end
  end

  context 'default values' do
    it 'can infer user from repository data' do
      hook = Travis::ServiceHook.new(data.reject{|key,v| key == 'user'}, payload)
      hook.user.should == "mojombo"
    end
    it 'should default to the "http" scheme' do
      hook = Travis::ServiceHook.new(data, payload)
      hook.scheme.should == 'http'
    end
    it 'should default to the "travis-ci.org" damain' do
      hook = Travis::ServiceHook.new(data.reject{|key,v| key == 'domain'}, payload)
      hook.domain.should == "travis-ci.org"
    end
  end

  def data
    {
      'user' => 'kronn',
      'token' => '5373dd4a3648b88fa9acb8e46ebc188a',
      'domain' => 'my-travis-ci.heroku.com'
    }
  end
  def payload
    {
      "after"   => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "ref"     => "refs/heads/master",
      "before"  => "4c8124ffcf4039d292442eeccabdeca5af5c5017",
      "compare" => "http://github.com/mojombo/grit/compare/4c8124ffcf4039d292442eeccabdeca5af5c5017...a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
      "forced"  => false,
      "created" => false,
      "deleted" => false,

      "repository" => {
        "name"  => "grit",
        "url"   => "http://github.com/mojombo/grit",
        "owner" => { "name" => "mojombo", "email" => "tom@mojombo.com" }
      },

      "commits" => [
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "[#WEB-249 status:31 resolution:1] stub git call for Grit#heads test",
          "added"     => [],
          "timestamp" => "2007-10-10T00:11:02-07:00",
          "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "06f63b43050935962f84fe54473a7c5de7977325"
        },
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "clean up heads test",
          "added"     => [],
          "timestamp" => "2007-10-10T00:18:20-07:00",
          "modified"  => ["test/test_grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/5057e76a11abd02e83b7d3d3171c4b68d9c88480",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "5057e76a11abd02e83b7d3d3171c4b68d9c88480"
        },
        {
          "distinct"  => true,
          "removed"   => [],
          "message"   => "add more comments throughout",
          "added"     => [],
          "timestamp" => "2007-10-10T00:50:39-07:00",
          "modified"  => ["lib/grit.rb", "lib/grit/commit.rb", "lib/grit/grit.rb"],
          "url"       => "http://github.com/mojombo/grit/commit/a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
          "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
          "id"        => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425"
        }
      ]
    }
  end
end
