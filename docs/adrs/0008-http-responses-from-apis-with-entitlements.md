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

There are four possible entitlement states when an API is processing a request:

 * Entitlement is valid, and has not expired, and the feature is "entitled"
 * Entitlement is valid, but has expired, and the the feature is "entitled"
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
