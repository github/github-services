service :freckle do |data, payload|
  
  data = {
    "subdomain" => "foo",
    "token" => "bar",
    "project" => "baz"
  }
  
  payload = {
    "after"  => "a47fd41f3aa4610ea527dcc1669dfdb9c15c5425",
    "ref"    => "refs/heads/master",
    "before" => "4c8124ffcf4039d292442eeccabdeca5af5c5017",
  
    "repository" => {
      "name"  => "grit",
      "url"   => "http://github.com/mojombo/grit",
      "owner" => { "name" => "mojombo", "email" => "tom@mojombo.com" }
    },
  
    "commits" => [
      {
        "removed"   => [],
        "message"   => "stub git call for Grit#heads test f:15",
        "added"     => [],
        "timestamp" => "2007-10-10T00:11:02-07:00",
        "modified"  => ["lib/grit/grit.rb", "test/helper.rb", "test/test_grit.rb"],
        "url"       => "http://github.com/mojombo/grit/commit/06f63b43050935962f84fe54473a7c5de7977325",
        "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
        "id"        => "06f63b43050935962f84fe54473a7c5de7977325"
      }, 
      {
        "removed"   => [],
        "message"   => "clean up heads test f:2hrs",
        "added"     => [],
        "timestamp" => "2007-10-10T00:18:20-07:00",
        "modified"  => ["test/test_grit.rb"],
        "url"       => "http://github.com/mojombo/grit/commit/5057e76a11abd02e83b7d3d3171c4b68d9c88480",
        "author"    => { "name" => "Tom Preston-Werner", "email" => "tom@mojombo.com" },
        "id"        => "5057e76a11abd02e83b7d3d3171c4b68d9c88480"
      },
      {
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
  
  entries, subdomain, token, project = 
    [], data['subdomain'].strip, data['token'].strip, data['project'].strip;
  
  payload['commits'].each do |commit|
    minutes = (commit["message"].split(/\s/).find{|item| /^f:/ =~ item }||'')[2,100]
    next unless minutes
    entries << {
      :date => Date.parse(commit["timestamp"]),
      :minutes => minutes,
      :description => commit["message"].gsub(/(\s|^)f:.*(\s|$)/){ $3 }.strip,
      :url => commit['url'],
      :project_name => project,
      :user => commit['author']['email']
    }
  end
  
  File.open('temp.log','w'){|w| w.write entries.to_json}
  # todo add freckle gem/import call
end