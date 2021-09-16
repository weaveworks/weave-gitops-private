# 8. HTTP Responses from APIs with Entitlements

Date: 2021-09-08

## Status

Proposed

## Context

We build APIs that are constrained by the entitlements an organisation has paid
for.

These entitlements control the features that are available, and expire after a
period of time.

Currently, it's expected that even after an entitlement has expired, we should
not terminate the functionality that it provided.

## Decision

For the purposes of discussion here, "valid" entitlements mean that the signed
JWT that contains the entitlement is considered valid by the JWT signature
mechanism.

To do this, the `exp` claim should not be used as the `licenced until` date,
otherwise anything that parses the entitlement after it has expired (but while
we continue to allow it to work), has to explicitly ignore the "expired" error
when validating, this also means that we can set an `exp` date on an entitlement
if we want to, and not alter the error handling for projects.

## API call responses

There are four possible entitlement states when an API is processing a request:

 * Entitlement is valid, and has not expired, and the feature is "entitled"
 * Entitlement is valid, but has expired, and the feature is "entitled"
 * Entitlement is valid, and has not expired, but the feature is not "entitled"
 * Entitlement is "invalid", perhaps the secret is corrupted in the cluster

APIs that require "entitlement" should should validate the entitlement token and
respond as follows:

### Entitlement is valid, and has not expired, and the feature is "entitled"
This is a standard 20x response, assuming that the request is otherwise valid.

### Entitlement is valid, but has expired, and the the feature is "entitled"
This is a standard 20x response, as above, but an additional header
`Entitlement-Expired-Message` should be added to the response with an
appropriate message indicating that the entitlement has expired e.g. _Your
entitlement has expired, please contact Weave Works_.

### Entitlement is valid, and has not expired, but the feature is not "entitled"
This should be a 401 response, the request is not authorised, and we should log
out details of the missing entitlement.

###  Entitlement is "invalid", perhaps the secret is corrupted in the cluster
This should be a 500 response, with an appropriate message logged out by the
component.

It's expected that we'll provide standard HTTP middlewares to handle most of
this, and further that the loaded entitlements will be cached at process startup
to minimise the cost of the checks.

## Consequences

 * The wego CLI and browser experience can check for the header, and display it
   to the user
 * Users can continue to use expired entitlements without breaking their
   functionality, but they will be encouraged to upgrade, if they have custom
   integrations, they will not necessarily see these messages
 * Any API service that requires an entitlement will be unusable without a
   pre-existing entitlement
 * If the organisation tampers with the validation, then the components will
   break

## Alternatives considered

 * We could rely on the `exp` claim, but this means that code that handles
   validation would always have to have a check for an expired entitlement
   error, and ignore it.
 * We could provide standard functions, similar to
   [`http.Error`](https://pkg.go.dev/net/http#Error) and move the
   rejection/header setting into the individual HTTP handlers, this increases
   the cost, and the approach outlined above _does not_ preclude this.
