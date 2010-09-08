%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require 'oauth'
require 'oauth/version'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.new('oauth', OAuth::VERSION) do |p|
  p.author = ['Pelle Braendgaard','Blaine Cook','Larry Halff','Jesse Clark','Jon Crosby', 'Seth Fitzsimmons']
  p.email = "pelleb@gmail.com"
  p.description = "OAuth Core Ruby implementation"
  p.summary = p.description
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.rubyforge_name       = p.name # TODO this is default value
  p.url = "http://oauth.rubyforge.org"

  p.extra_deps         = [
    ['ruby-hmac','>= 0.3.1']
  ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"],
    ['actionpack'],
    ['rack']
  ]

  p.clean_globs |= %w[**/.DS_Store tmp *.log **/.*.sw? *.gem .config **/.DS_Store]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]
