= Tinder - get the Campfire started

Tinder is a library for interfacing with Campfire, the chat application from 37Signals. Unlike Marshmallow, it is designed to be a full-featured API (since 37Signals doesn't provide a real one), allowing you to programatically manage and speak/listen in chat rooms.

== Usage

  campfire = Campfire.new 'mysubdomain'
  campfire.login 'myemail@example.com', 'mypassword'
  room = campfire.create_room 'New Room', 'My new campfire room to test tinder'
  room.rename 'New Room Name'
  room.speak 'Hello world!'
  room.paste "my pasted\ncode"
  room.destroy
  
  See the RDoc for more details.

== Requirements

* Active Support
  gem install activesupport
* Hpricot
  gem install hpricot
  
== Installation

Tinder can be installed as a gem or a Rails plugin:

  gem install tinder
  
  script/plugin install http://source.collectiveidea.com/public/tinder/trunk
  
== Development

The source for Tinder is available at http://source.collectiveidea.com/public/tinder/trunk. Development can be followed at http://opensoul.org/tags/tinder.  Contributions are welcome!

== ToDo

* Tests! (unit and remote)
* Log in via guest url
* Marshmallow-style integration scripts for exception notification and continuous integration
