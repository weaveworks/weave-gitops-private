# 2. Upgrade from weave-gitops to weave-gitops-enterprise

Date: 2021-08-11

## Status

Drafting

## Context

Part of our weave-gitops business model is to encourage happy and interested weave-gitops users to upgrade to a paid version with more features. We want to make this option for them visible and easy to take advantage of.

Here we discuss the different potential technical implementations for how a user can upgrade to the enterprise edition.

## Technical context around how WG and WGE are related

### WG

WG is primarily a cli tool that

- installs flux
- manipulates git repos

It also includes:

- an API server that allows a UI to query what applications have been added to git etc.

The API server and UI are the main integration points with WGE

### Relation

- WG is OSS and WGE is closed source
- As runtime integration of WG and WGE is tricky they will be integrated at **build time**.
  - WGE will be a standalone distribution that will include all WG functionality.
  - WGE will import said functionality by including WG code as some/all of:
    - js dependencies (ui)
    - golang dependencies (api-server)
    - docker images (api-server?)
- WG and WGE are both different profiles

## On upgrading

After upgrading:

- The user should still have all the WG functionality availble to them via WGE
- Whatever ingress method used to access the WG UI should now show the WGE UI.
  - Q. Is ingress management a WG responsibility that WGE will take over?
- Whatever CLI tools that queried the WG api-server should still work and query the WGE api-server
  - Q. Via same ingress as UI?
- Any state that WG has built up should be inherited and preserved by WGE
  - We don't want to disrupt any user workloads / deployments
  - There might be configuration options / preferences that should be preserved?

Notes:

- Upgrading WG to WGE will require replacing one with the other

## Options

- Some `wego upgrade` command that

## Proposal

- An entitlements service to generate entitlements (expiration date, enabled feature list) signed by a private key
- Code in WGE services that includes the public key to validate entitlement authenticity and show an warning if entitlements have expired.
- `mccp upgrade` command that will remove the wego deployments and replace them with WGE deployments
  - Some preflight checking for version compatibility support
  - Any ingress points should be preserved. E.g. any services that WG creates to support accessing its api endpoints should be re-created with the same name / ports.

## Questions

Q. How can we best replace the WG deployments with WGE deployments?

## Decision

??
