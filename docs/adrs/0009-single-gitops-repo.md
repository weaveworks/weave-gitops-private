# 9. Single GitOps repository

Date: 2021-10-12

## Status

Accepted

## Context

Currently, there is ambiguity around the GitOps repository and whether users can, or should, have multiple GitOps repositories referenced from a single cluster.  Supporting multiple GitOps repositories for a single cluster complicates the customers' environment and complicates the APIs, CLIs, and WebUI for Weave GitOps.  Here are some questions/issues that will need to address if we are to support multiple GitOps repositories in a single cluster: 
  * Which repository contains the GitOps Runtime
  * When creating a cluster, which GitOps repository should own it
  * When adding a profile or application, which repository should it go into
  * We won't be able to perform Atomic changes across multiple repositories
  * How do we keep policy checks and restrictions consistent across repositories? 
  * How would we keep conflicting policies out of the environment?
  * Would CI systems need to know about the other repositories?
  * Two repositories would be a challenge - what about ten?
  * What is the process for recovering a cluster with multiple GitOps repositories?

**NOTE** This is only referring to the GitOps repository.  Application manifests will likely live in their repositories and be references (via kustomize or Helm Releases) from the GitOps repository.

## Decision

Restrict a GitOps management cluster to a single GitOps repository. Also, for the near team, manufactured leaf clusters share the GitOps repository from their management cluster.

## Consequences

* `gitops install` can only be run once on a cluster.
  * A platform team won't have a separate GitOps repository
* Customers may require environments with different restrictions.  For example,  Dev and Staging can live together in a single repository, but Production has different users/teams.
  * Requires applications and profiles to be added separately for each GitOps repository
* Customers are encouraged to leverage CODEOWNERS (or equivalent) where necessary to restrict changes. 
* The API (and UI) only need to worry about a single GitOps repository.  Thereby simplifying the Weave GitOps interfaces

## Open questions
* What are the scaling limitations to this approach?  E.g., A single GitOps repository can support 10s of applications with 10s of clusters.  
