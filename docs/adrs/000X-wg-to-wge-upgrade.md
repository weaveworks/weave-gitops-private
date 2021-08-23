# 2. Upgrade from weave-gitops to weave-gitops-enterprise

Date: 2021-08-11

## Status

Drafting

## Problem

Part of our weave-gitops business model is to encourage happy and interested weave-gitops users to upgrade to a paid version with more features. We want to make this option for them visible and easy to take advantage of.

Here we discuss the different potential technical implementations for how a user can upgrade from weave-gitops (WG) to weave-gitops-enterprise (WGE).

## Context

### `weave-gitops` core (WG)

The [proposed](https://github.com/weaveworks/weave-gitops/pull/590) (not current) architecture for WG:

1. the **WG service**: an `api-server` deployment that:
   - hosts HTTP endpoints that talk to git-provider and kubernetes
   - serves a **web-ui** accessed via some ingress that queries this http api
2. cli tool `wego` that:
   - queries the http endpoints of the api-server via some ingress
   - There is [an ADR for cli plugins](https://github.com/weaveworks/weave-gitops-private/pull/31/files) to allow us to install additional WGE functionality into the cli UX but that is out of scope for this doc.

### How WG and `weave-gitops-enterprise` (WGE) are related

- WG is OSS and WGE is closed source
- WGE will integrate WG functionality at build time. ([WG/WGE UI and server integration ADR](https://github.com/weaveworks/weave-gitops/pull/600))
- WGE will be a standalone profile that will include all WG functionality.

## Proposed upgrade implementation

### Remove the WG api-server and install WGE

The user will follow steps to remove the WG api-server component that lives in the cluster and replace them with WGE components. We'll use gitops for this process, removing WG will require some `git rm`ing.

WG and WGE are not installed at the same time and so the system can look "more identical": providing k8s service/ingress with the same name/namespace so a replacement will be transparent to other services and the `wego` cli.

Rough steps:

1. Remove WG
   - `git rm -r profiles/wg` then `git commit && git push`
2. Install WGE
   - `pctl add weave-gitops-enterprise`
3. Check PR(s) and merge

## Other upgrade implementation options considered and discarded

### 1. Install WGE via the WG UI

Use the WG web UI to add a WGE profile repository and then install WGE. However we haven't implemented profile support in WG yet, we might revisit this in the future.

### 2. Keep `WG` api-server installed and use it to handle relevent requests

Leave the WG api-server in place and add additional functionality that routes to it when needed. However WGE implements all WG functionality so mixing parts of them together is just expanding out the "testing matrix".

## On upgrading

After upgrading:

- The user should still have all the WG functionality available to them via WGE
- Any state that WG has built up should be inherited and preserved by WGE
  - We don't want to disrupt any user workloads / deployments
  - If WG is installing an OAuth thingy the secrets associated with that should be preserved

## Other supporting services

### Entitlements

WGE should show a warning that the user is in violation of the license agreement if they don't have a valid entitlements file.

This warning should appear in:

- The web UI on each page
- In the output of each `cli` command.

## Work breakdown

### Add a WGE Profile

- Write a private profile to wrap the WGE helm chart.
- Publish the private profile to a private WGE profile catalog
- Establish some way of giving customers access to this private repo.

### Entitlements

- Add a cli tool / instructions for CX to generate entitlements (expiration date, enabled feature list) signed by a private key
  - _Note: we have example code to implement this from good old WKP_
- Code in WGE services that includes the public key to validate entitlement authenticity and show an warning if entitlements have expired.
  - _Note: we have example code to implement this from good old WKP_

We want to establish a _convention_ for storing the entitlements so perhaps it tries to create a PR in `weave-gitops-private/entitlements` by default with a `--dry-run` option to support saving them elsewhere like Saleforce.

_The dockerhub authentication will be removed._

### Add docs on how to upgrade

E.g. `git rm wg` && `pctl add wge` as described above

### Add docs on how to downgrade

Revert the above PR

### Merge (MCCP) weave-gitops-enterprise docs with weave-gitops

Migrate the MCCP docs from docs.wkp to docs.gitops and annotate sections of docs with **Enterprise feature** labels where appropriate.
