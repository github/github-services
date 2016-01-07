require File.expand_path('../web', __FILE__)

class Service::Snapci < Service::Web
  self.title = "Snap CI"
  url "https://snap-ci.com"
  logo_url "https://snap-ci.com/assets/favicons/snap.ico"

  supported_by :web => 'https://snap-ci.com/contact-us', :email => 'snap-ci@thoughtworks.com'
  maintained_by :github => 'snap-ci'
  default_events :push, :member
end
