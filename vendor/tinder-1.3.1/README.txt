= Tinder - get the Campfire started


This branch is a rewrite of Tinder to use the official Campfire API. The API is intended to be backwards compatible so consumers can easily migrate off the HTML API.

-- Joshua Peek (Programmer, 37signals)


Tinder is a library for interfacing with Campfire, the chat application from 37Signals. Unlike Marshmallow, it is designed to be a full-featured API (since 37Signals doesn't provide a real one), allowing you to programatically manage and speak/listen in chat rooms.

== Usage

  campfire = Tinder::Campfire.new 'mysubdomain'
  campfire.login 'myemail@example.com', 'mypassword'

  room = campfire.create_room 'New Room', 'My new campfire room to test tinder'
  room.rename 'New Room Name'
  room.speak 'Hello world!'
  room.paste "my pasted\ncode"
  room.destroy

  room = campfire.find_room_by_guest_hash 'abc123', 'John Doe'
  room.speak 'Hello world!'
  
  See the RDoc for more details.

== Installation

Tinder can be installed as a gem or a Rails plugin:

  gem install tinder
  
  script/plugin install git://github.com/collectiveidea/tinder.git
  
== How to contribute

If you find what looks like a bug:

1. Check the GitHub issue tracker to see if anyone else has had the same issue.
   http://github.com/collectiveidea/tinder/issues/
2. If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

1. Fork the project on github.
   http://github.com/collectiveidea/tinder
2. Make your changes with tests.
3. Commit the changes without making changes to the Rakefile, VERSION, or any other files that aren't related to your enhancement or fix
4. Send a pull request.

== ToDo

* Tests! (unit and remote)
* Marshmallow-style integration scripts for exception notification and continuous integration
