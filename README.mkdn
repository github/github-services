GitHub Services
===============

How the services work
---------------------

1. A post-receive background job is submitted when someone pushes their
   commits to GitHub
2. If the repository the commits belong to has any "Service Hooks" setup, the
   job makes a request to `http://services-server/service_name/push` with the
   following data:
    - `params[:payload]` containing all of the commit data (the same data you get using the API)
    - `params[:data]` containing the service data (username, password, room, etc)
3. Sinatra (github-services.rb) processes the request (twitters your data, says
   something in campfire, posts it to lighthouse, etc)
4. Rinse and repeat

Steps to contributing
---------------------

1. Fork the project
2. Create a new file in /services/ called `service_name.rb`, using the [following
   template](https://github.com/github/github-services/tree/master/services#readme):

    ```ruby
    class Service::ServiceName < Service
      def receive_push
      end
    end
    ```

3. Vendor any external gems your code relies on, and make sure it is
   specified in the Gemfile.
4. Add documentation to `docs/service_name` (refer to the others for guidance)
5. Send a pull request from your fork to [github/github-services](https://github.com/github/github-services)
6. Once it's accepted we'll add any new necessary data fields to the GitHub
   front-end so people can start using your addition.

*Patches including tests are encouraged*

A huge thanks goes out to [our many contributors](https://github.com/github/github-services/contributors)!

Running the server locally
--------------------------

1. [sudo] gem install hpricot
2. git clone git://github.com/github/github-services.git
3. cd github-services
4. ruby github-services.rb

* Bugs in the code should be filed under the Issues tab
* Problems with the service hooks can be filed
  [here](https://github.com/contact)

How to test your service
------------------------

You can test your service in a ruby irb console:

1. Run `rake console` to start irb.
2. Instantiate your Service:

    ```ruby
    svc = Service::MyService.new(:push,
      # Hash of configuration information.
      {'token' => 'abc'},
      # Hash of payload.
      {'blah' => 'payload!'})

    svc.receive_push
    ```

3. The third argument is optional if you just want to use the sample
   payload.

    ```ruby
    svc = Service::MyService.new(:push,
      # Hash of configuration information.
      {'token' => 'abc'})

    svc.receive_push
    ```

You can also test your hook with the Sinatra web service:

1. Start the github-services Sinatra server with `ruby github-services.rb`. By
   default, it runs on port 8080.
2. Edit the docs/github_payload file as necessary to test your service.  (Usually
   just editing the "data" values but leaving the "payload" alone.)
3. Send the docs/github_payload file to your service by calling:
   `./script/deliver_payload [service-name]`
