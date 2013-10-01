# Contributing

GitHub will accept service hooks for the following types of services:

* Production web applications
* Popular internet protocols (Email, IRC, etc).

In order to provide quality service and support for our users, we require the
following:

* Implement endpoints that take [the new payload](https://github.com/github/github-services/blob/56baa4ce03e64ebf67105ee22f752bf7c2383274/lib/services/http_post.rb#L13-L16), completely unmodified.
  * Good example: [Simperium](https://github.com/github/github-services/blob/master/lib/services/simperium.rb)
    has minimal logic (just config parameters, an HTTP header, and a custom url).
  * Bad example: [CodeClimate](https://github.com/github/github-services/blob/master/lib/services/codeclimate.rb)
    uses the old payload format.
  * Bad Example: [Campfire](https://github.com/github/github-services/blob/master/lib/services/campfire.rb)
    modifies the payload to make multiple calls to the Campfire service.
* Thorough documentation about what the hook does, and what the options do.
* Tested code that works.  If we have to make changes to the Services infrastructure,
it helps a lot to have passing tests so we know we're not breaking things.

Any new hooks that don't meet the above criteria will be rejected.

We'd also like the following information to help provide quality service and
support to our users:

* A URL for the service (if applicable).
* A URL to a logo for the service (png or gif preferred).
* A maintainer.  Someone that GitHub can contact in the event of bugs.  We prefer
GitHub users, so that we can file issues directly to the github/github-services
Repository.
* A support contact for our users that have problems.  This can be a GitHub user,
an email address, or link to a contact form.

If we need support from any hooks without this data, we will look for the most
active contributor to the hook file itself.

You can annotate this directly in the hook like so:

```ruby
class Service::MyService < Service
  string :project, :api_token

  # only include 'project' in the debug logs, skip the api token.
  white_list :project

  default_events :push, :issues, :pull_request

  url "http://myservice.com"
  logo_url "http://myservice.com/logo.png"

  # Technoweenie on GitHub is pinged for any bugs with the Hook code.
  maintained_by :github => 'technoweenie'

  # Support channels for user-level Hook problems (service failure,
  # misconfigured
  supported_by :web => 'http://my-service.com/support',
    :email => 'support@my-service.com'
end
```

You can annotate Supporters and Maintainers by the following methods:

* `:github` - a GitHub login.
* `:web` - A URL to a contact form.
* `:email` - An email address.
* `:twitter` - A Twitter handle.

How to test your service
------------------------

You can test your service in a ruby irb console:

0. Cache gems and install them to `vendor/gems` by doing:
   `script/bootstrap`
1. Start a console: `script/console`
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

Other hook types
----------------

The default hook for a service is `push`. You may wish to have services respond
to other event types, like `pull_request` or `issues`. The full list may be
found in [service.rb](https://github.com/github/github-services/blob/master/lib/service.rb#L79-L83).
Unless your service specifies `default_events <list_of_types>`, only the `push`
hook will be called, see
[service.rb#default_events](https://github.com/github/github-services/blob/55a1fb10a44a80dec6a744d0828c769b00d97ee2/lib/service.rb#L122-L133).

To make use of these additional types, your service will either need to define
`receive_<type>` (like `receive_pull_request_review_comment`) or a generic
`receive_event`.

You can read more about the Hooks in the [API Documentation](http://developer.github.com/v3/repos/hooks/).
