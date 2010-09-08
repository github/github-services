# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{oauth}
  s.version = "0.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pelle Braendgaard", "Blaine Cook", "Larry Halff", "Jesse Clark", "Jon Crosby", "Seth Fitzsimmons"]
  s.date = %q{2009-03-23}
  s.default_executable = %q{oauth}
  s.description = %q{OAuth Core Ruby implementation}
  s.email = %q{oauth-ruby@googlegroups.com}
  s.executables = ["oauth"]
  s.extra_rdoc_files = ["History.txt", "License.txt", "Manifest.txt", "README.rdoc", "website/index.txt"]
  s.files = ["History.txt", "License.txt", "Manifest.txt", "README.rdoc", "Rakefile", "TODO", "bin/oauth", "examples/yql.rb", "lib/oauth.rb", "lib/oauth/oauth.rb", "lib/oauth/cli.rb", "lib/oauth/client.rb", "lib/oauth/client/action_controller_request.rb", "lib/oauth/client/helper.rb", "lib/oauth/client/net_http.rb", "lib/oauth/consumer.rb", "lib/oauth/errors.rb", "lib/oauth/errors/error.rb", "lib/oauth/errors/problem.rb", "lib/oauth/errors/unauthorized.rb", "lib/oauth/helper.rb", "lib/oauth/oauth_test_helper.rb", "lib/oauth/request_proxy.rb", "lib/oauth/request_proxy/action_controller_request.rb", "lib/oauth/request_proxy/base.rb", "lib/oauth/request_proxy/jabber_request.rb", "lib/oauth/request_proxy/mock_request.rb", "lib/oauth/request_proxy/net_http.rb", "lib/oauth/request_proxy/rack_request.rb", "lib/oauth/server.rb", "lib/oauth/signature.rb", "lib/oauth/signature/base.rb", "lib/oauth/signature/hmac/base.rb", "lib/oauth/signature/hmac/md5.rb", "lib/oauth/signature/hmac/rmd160.rb", "lib/oauth/signature/hmac/sha1.rb", "lib/oauth/signature/hmac/sha2.rb", "lib/oauth/signature/md5.rb", "lib/oauth/signature/plaintext.rb", "lib/oauth/signature/rsa/sha1.rb", "lib/oauth/signature/sha1.rb", "lib/oauth/token.rb", "lib/oauth/tokens/access_token.rb", "lib/oauth/tokens/consumer_token.rb", "lib/oauth/tokens/request_token.rb", "lib/oauth/tokens/server_token.rb", "lib/oauth/tokens/token.rb", "lib/oauth/version.rb", "oauth.gemspec", "script/destroy", "script/generate", "script/txt2html", "setup.rb", "tasks/deployment.rake", "tasks/environment.rake", "tasks/website.rake", "test/cases/oauth_case.rb", "test/cases/spec/1_0-final/test_construct_request_url.rb", "test/cases/spec/1_0-final/test_normalize_request_parameters.rb", "test/cases/spec/1_0-final/test_parameter_encodings.rb", "test/cases/spec/1_0-final/test_signature_base_strings.rb", "test/keys/rsa.cert", "test/keys/rsa.pem", "test/test_access_token.rb", "test/test_action_controller_request_proxy.rb", "test/test_consumer.rb", "test/test_helper.rb", "test/test_hmac_sha1.rb", "test/test_net_http_client.rb", "test/test_net_http_request_proxy.rb", "test/test_rack_request_proxy.rb", "test/test_request_token.rb", "test/test_rsa_sha1.rb", "test/test_server.rb", "test/test_signature.rb", "test/test_signature_base.rb", "test/test_signature_plain_text.rb", "test/test_token.rb", "website/index.html", "website/index.txt", "website/javascripts/rounded_corners_lite.inc.js", "website/stylesheets/screen.css", "website/template.rhtml"]
  s.has_rdoc = true
  s.homepage = %q{http://oauth.rubyforge.org}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{oauth}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{OAuth Core Ruby implementation}
  s.test_files = ["test/cases/spec/1_0-final/test_construct_request_url.rb", "test/cases/spec/1_0-final/test_normalize_request_parameters.rb", "test/cases/spec/1_0-final/test_parameter_encodings.rb", "test/cases/spec/1_0-final/test_signature_base_strings.rb", "test/test_access_token.rb", "test/test_action_controller_request_proxy.rb", "test/test_consumer.rb", "test/test_helper.rb", "test/test_hmac_sha1.rb", "test/test_net_http_client.rb", "test/test_net_http_request_proxy.rb", "test/test_rack_request_proxy.rb", "test/test_request_token.rb", "test/test_rsa_sha1.rb", "test/test_server.rb", "test/test_signature.rb", "test/test_signature_base.rb", "test/test_signature_plain_text.rb", "test/test_token.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby-hmac>, [">= 0.3.1"])
      s.add_development_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_development_dependency(%q<actionpack>, [">= 0"])
      s.add_development_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<hoe>, [">= 1.8.0"])
    else
      s.add_dependency(%q<ruby-hmac>, [">= 0.3.1"])
      s.add_dependency(%q<newgem>, [">= 1.2.3"])
      s.add_dependency(%q<actionpack>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<hoe>, [">= 1.8.0"])
    end
  else
    s.add_dependency(%q<ruby-hmac>, [">= 0.3.1"])
    s.add_dependency(%q<newgem>, [">= 1.2.3"])
    s.add_dependency(%q<actionpack>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<hoe>, [">= 1.8.0"])
  end
end
