# Contributing

GitHub will accept service hooks for the following types of services:

* Production web applications
* Popular internet protocols (Email, IRC, etc).

In order to provide quality service and support for our users, we require the
following:

* Implement endpoints that take the full, untouched payload.
Good example: [CodeClimate](https://github.com/github/github-services/blob/master/services/codeclimate.rb).
Bad Example: [Campfire](https://github.com/github/github-services/blob/master/services/campfire.rb).
* Thorough documentation about what the hook does, and what the options do.
* Tested code that works.  If we have to make changes to the Services infrastructure,
it helps a lot to have passing tests so we know we're not breaking things.

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

