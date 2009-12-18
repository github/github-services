# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{crack}
  s.version = "0.1.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Nunemaker"]
  s.date = %q{2009-07-19}
  s.email = %q{nunemaker@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "History",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION.yml",
     "crack.gemspec",
     "lib/crack.rb",
     "lib/crack/core_extensions.rb",
     "lib/crack/json.rb",
     "lib/crack/xml.rb",
     "test/crack_test.rb",
     "test/data/twittersearch-firefox.json",
     "test/data/twittersearch-ie.json",
     "test/hash_test.rb",
     "test/json_test.rb",
     "test/string_test.rb",
     "test/test_helper.rb",
     "test/xml_test.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/jnunemaker/crack}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{crack}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Really simple JSON and XML parsing, ripped from Merb and Rails.}
  s.test_files = [
    "test/crack_test.rb",
     "test/hash_test.rb",
     "test/json_test.rb",
     "test/string_test.rb",
     "test/test_helper.rb",
     "test/xml_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
