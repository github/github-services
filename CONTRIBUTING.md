# Contributing

**NOTE**: GitHub no longer accepts new services that are based on HTTP. If you'd like to integrate
your application or service with GitHub, you should use [webhooks][webhooks] which will `POST` a
payload to your server for each event.

## Creating a new service

GitHub will only accept new services that add functionality for a non-HTTP based endpoint (e.g.,
XMPP MUC, IRC, or email services).

If you'd like to create a new service, please open an issue describing your proposed service. We
will review your proposal and let you know if it meets requirements described above.

## Updating an existing service

GitHub will only accept pull requests to existing services that implement bug fixes or security
improvements. We no longer accept feature changes to existing services.

We strongly encourage existing services to move to an [OAuth based webhook integration][webhooks]
if possible. You will better be able to control the complete integration including installation
and updates.

All pull requests will be reviewed by multiple GitHub staff members before being merged.
To allow ample time for review, there may be a substantial delay between the pull request being created and the pull requested
being merged by GitHub's staff.

[webhooks]: https://developer.github.com/webhooks/
