module Service::StatusHelpers
  def self.sample_status_payload
    {"sha"=>"7b80eb100206a56523dbda6202d8e5daa05e265b",
     "name"=>"mojombo/grit",
     "target_url"=>nil,
     "context"=>"default",
     "description"=>nil,
     "state"=>"success",
     "branches"=> [
       {
         "name"=>"master",
         "commit"=> {
           "sha"=>"69a8b72e2d3d955075d47f03d902929dcaf74033", 
           "url"=> "https://api.github.com/repos/mojombo/grit/commits/69a8b72e2d3d955075d47f03d902929dcaf74033"
         }
       },
       {
         "name"=>"changes",
         "commit"=> {
           "sha"=>"05c588ba8cd510ecbe112d020f215facb17817a6",
           "url"=> "https://api.github.com/repos/mojombo/grit/commits/05c588ba8cd510ecbe112d020f215facb17817a6"
         }
       },
       {
         "name"=>"gh-pages",
         "commit"=> {
           "sha"=> "993b46bdfc03ae59434816829162829e67c4d490", 
           "url"=> "https://api.github.com/repos/mojombo/grit/commits/993b46bdfc03ae59434816829162829e67c4d490"
         }
       }
     ],
     "commit"=> {
       "sha"=>"7b80eb100206a56523dbda6202d8e5daa05e265b",
       "commit" => {
         "author" => {
           "name" =>"rtomayko",
           "email" =>"rtomayko@users.noreply.github.com",
           "date" =>"2014-05-20T22:26:15Z"
         },
         "committer" => {
           "name"=>"rtomayko",
           "email"=>"rtomayko@users.noreply.github.com",
           "date"=>"2014-05-20T22:26:15Z"
         },
         "message"=>"Create README.md",
         "tree"=> {
           "sha"=>"aa81d3d185d48ac4eb935b57d9aa54e8eb0dcd9d",
           "url"=> "https://api.github.com/repos/mojombo/grit/git/trees/aa81d3d185d48ac4eb935b57d9aa54e8eb0dcd9d"
         },
         "url"=> "https://api.github.com/repos/mojombo/grit/git/commits/7b80eb100206a56523dbda6202d8e5daa05e265b",
         "comment_count"=>23
       },
       "url"=> "https://api.github.com/repos/mojombo/grit/commits/7b80eb100206a56523dbda6202d8e5daa05e265b",
       "html_url"=> "https://github.com/mojombo/grit/commit/7b80eb100206a56523dbda6202d8e5daa05e265b",
       "comments_url"=> "https://api.github.com/repos/mojombo/grit/commits/7b80eb100206a56523dbda6202d8e5daa05e265b/comments",
       "author"=> {
         "login"=>"rtomayko",
         "id"=>6752317,
         "avatar_url"=>"https://avatars.githubusercontent.com/u/6752317?",
         "gravatar_id"=>"258ae60b5512c8402b93673b7478d9c6",
         "url"=>"https://api.github.com/users/rtomayko",
         "type"=>"User",
         "site_admin"=>false
       },
       "committer"=> {
         "login"=>"rtomayko",
         "id"=>6752317,
         "avatar_url"=>"https://avatars.githubusercontent.com/u/6752317?",
         "gravatar_id"=>"258ae60b5512c8402b93673b7478d9c6",
         "url"=>"https://api.github.com/users/rtomayko",
         "type"=>"User",
         "site_admin"=>false
       },
       "parents"=>[]
     },
     "repository"=> {
       "id"=>20000106, 
       "name"=>"grit",
       "full_name"=>"mojombo/grit",
       "owner"=> {
         "login"=>"rtomayko",
         "id"=>6752317,
         "avatar_url"=>"https://avatars.githubusercontent.com/u/6752317?",
         "gravatar_id"=>"258ae60b5512c8402b93673b7478d9c6",
         "url"=>"https://api.github.com/users/rtomayko",
         "type"=>"User",
         "site_admin"=>false
       },
       "private"=>false,
       "html_url"=>"https://github.com/mojombo/grit",
       "description"=>"",
       "fork"=>false,
       "url"=>"https://api.github.com/repos/mojombo/grit",
       "default_branch"=>"master"
     },
     "sender"=> {
       "login"=>"rtomayko",
       "id"=>6752317,
       "avatar_url"=>"https://avatars.githubusercontent.com/u/6752317?",
       "gravatar_id"=>"258ae60b5512c8402b93673b7478d9c6",
       "url"=>"https://api.github.com/users/rtomayko",
       "received_events_url"=> "https://api.github.com/users/rtomayko/received_events",
       "type"=>"User",
       "site_admin"=>false
     }
    }
  end
end
