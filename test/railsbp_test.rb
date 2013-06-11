require File.expand_path('../helper', __FILE__)

class RailsbpTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc = service(data, payload)
  end

  def test_reads_token_from_data
    assert_equal "xAAQZtJhYHGagsed1kYR", @svc.token
  end

  def test_reads_default_railsbp_url_from_data
    assert_equal "https://railsbp.com", @svc.railsbp_url
  end

  def test_reads_custom_railsbp_url_from_data
    data = { "token" => "xAAQZtJhYHGagsed1kYR", "railsbp_url" => "http://railsbp.heroku.com" }
    svc = service(data, payload)
    assert_equal "http://railsbp.heroku.com", svc.railsbp_url
  end

  def test_strips_whitespace_from_form_values
    data = { "token" => "  xAAQZtJhYHGagsed1kYR  ", "railsbp_url" => "  http://railsbp.heroku.com  " }
    svc = service(data, payload)
    assert_equal "xAAQZtJhYHGagsed1kYR", svc.token
    assert_equal "http://railsbp.heroku.com", svc.railsbp_url
  end

  def test_posts_payload
    @stubs.post "/" do |env|
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end
    @svc.receive_push
  end

  def service(*args)
    super Service::Railsbp, *args
  end

  def data
    { "token" => "xAAQZtJhYHGagsed1kYR", 'railsbp_url' => '' }
  end

  def payload
    {
      "before" => "a6ab010bc21151e238c73d5229c36892d51c2d4f",
      "repository" => {
        "url" => "https =>//github.com/railsbp/rails-bestpractices.com",
        "name" => "rails-bestpractice.com",
        "description" => "rails-bestpractices.com",
        "watchers" => 64,
        "forks" => 14,
        "private" => 0,
        "owner" => {
          "email" => "flyerhzm@gmail.com",
          "name" => "Richard Huang"
        }
      },
      "commits" => [
        {
          "id" => "af9718a9bee64b9bbbefc4c9cf54c4cc102333a8",
          "url" => "https =>//github.com/railsbp/rails-bestpractices.com/commit/af9718a9bee64b9bbbefc4c9cf54c4cc102333a8",
          "author" => {
            "email" => "flyerhzm@gmail.com",
            "name" => "Richard Huang"
          },
          "message" => "fix typo in .travis.yml",
          "timestamp" => "2011-12-25T18 =>57 =>17+08 =>00",
          "modified" => [".travis.yml"]
        },
        {
          "id" => "473d12b3ca40a38f12620e31725922a9d88b5386",
          "url" => "https =>//github.com/railsbp/rails-bestpractices.com/commit/473d12b3ca40a38f12620e31725922a9d88b5386",
          "author" => {
            "email" => "flyerhzm@gmail.com",
            "name" => "Richard Huang"
          },
          "message" => "copy config yaml files for travis",
          "timestamp" => "2011-12-25T20 =>36 =>34+08 =>00"
        }
      ],
      "after" => "473d12b3ca40a38f12620e31725922a9d88b5386",
      "ref" => "refs/heads/master"
    }
  end
end
