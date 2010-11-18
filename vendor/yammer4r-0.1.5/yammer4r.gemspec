Gem::Specification.new do |s|
  s.name    = 'yammer4r'
  s.version = '0.1.5'
  s.date    = '2009-12-29'

  s.summary = "Yammer access for ruby"
  s.description = "Yammer4R provides an object based API to query or update your Yammer account via pure Ruby.  It hides the ugly HTTP/REST code from your code."

  s.authors  = ['Jim Patterson', 'Jason Stewart', 'Peter Moran']
  s.email    = 'workingpeter@gmail.com'
  s.homepage = 'http://github.com/pmoran/yammer4r'

  s.has_rdoc = false
  s.files = %w(README
               example.rb
               oauth.yml.template
               Rakefile
               TODO
               bin/yammer_create_oauth_yml.rb
               lib/yammer4r.rb
               lib/yammer/client.rb
               lib/yammer/message.rb
               lib/yammer/message_list.rb
               lib/yammer/user.rb
               lib/ext/core_ext.rb
               spec/spec_helper.rb
               spec/yammer/client_spec.rb)

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mash>, [">= 0.0.3"])
      s.add_runtime_dependency(%q<json>, [">= 1.1.7"])
      s.add_runtime_dependency(%q<oauth>, [">= 0.3.5"])
    else
      s.add__dependency(%q<mash>, [">= 0.0.3"])
      s.add__dependency(%q<json>, [">= 1.1.7"])
      s.add__dependency(%q<oauth>, [">= 0.3.5"])
    end
  else
    s.add__dependency(%q<mash>, [">= 0.0.3"])
    s.add__dependency(%q<json>, [">= 1.1.7"])
    s.add__dependency(%q<oauth>, [">= 0.3.5"])
  end

end

