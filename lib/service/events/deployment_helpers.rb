module Service::DeploymentHelpers
  def self.sample_deployment_payload
    {
      "id"=>721,
      "ref"=>"master",
      "sha"=>"9be5c2b9c34c1f8beb0cec30bb0c875d098f45ef",
      "name"=>"atmos/my-robot",
      "environment"=>"production",
      "payload"=>{
        "config"=>{
          "heroku_production_name"=>"my-app"
        }
      },
      "description"=>nil,
      "repository"=>
      {
        "id"=>16650088,
        "name"=>"my-robot",
        "full_name"=>"atmos/my-robot",
        "owner"=>
        {
          "login"=>"atmos",
           "id"=>6626297,
           "avatar_url"=> "https://identicons.github.com/86f5d368c1103c6a77ddb061e7727e46.png",
          "gravatar_id"=>nil,
          "url"=>"https://api.github.com/users/atmos",
          "html_url"=>"https://github.com/atmos",
          "type"=>"Organization",
          "site_admin"=>false
        },
        "private"=>true,
        "html_url"=>"https://github.com/atmos/my-robot",
        "description"=>"SlackHQ hubot for atmos",
        "fork"=>false,
        "created_at"=>"2014-02-08T18:40:20Z",
        "updated_at"=>"2014-02-20T00:00:11Z",
        "pushed_at"=>"2014-02-16T02:00:37Z",
        "default_branch"=>"master",
        "master_branch"=>"master"
      },
      "sender"=>
      {
          "login"=>"atmos",
          "id"=>38,
          "avatar_url"=> "https://gravatar.com/avatar/a86224d72ce21cd9f5bee6784d4b06c7?d=https%3A%2F%2Fidenticons.github.com%2Fa5771bce93e200c36f7cd9dfd0e5deaa.png&r=x",
          "gravatar_id"=>"a86224d72ce21cd9f5bee6784d4b06c7",
          "url"=>"https://api.github.com/users/atmos",
          "html_url"=>"https://github.com/atmos",
          "type"=>"User",
          "site_admin"=>true
      }
    }
  end
end
