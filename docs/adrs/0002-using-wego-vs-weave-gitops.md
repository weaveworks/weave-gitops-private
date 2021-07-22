# 2. Using wego vs. weave-gitops

Date: 2021-07-21

## Status

Proposed

## Context

Our code, documentation, and Kubernetes object naming has a mixture of wego, weave-gitops, and Weave GitOps.  This ADR guides when and where you should use one over the other.

## Decision

### Weave GitOps
Use in all user-facing documentation, except when presenting actual CLI commands the user can execute.  It should be spelled out and follow this capitalization `Weave GitOps`.  

Including: 
* go docs for functions, packages, and variables
* Online documentation 
* Blogs

### wego
* The name of the CLI binary. 
* The API group will be `wego.weave.works`
* The default Kubernetes namespace will be `wego-system`
* When naming Weave GitOps objects in Kubernetes, they will have a `wego-` prefix
* Code variables - developer choice
* Code comments - developer choice, except for public facing docs

### weave-gitops
* Name of code repository for Weave GitOps core
* **change** The release packages will be prefixed with `weave-gitops`
* **new** When we have additional distribution packages, they will use `weave-gitops` as a prefix as well


## Consequences

Using the shorter version, wego, as a prefix for naming objects, reduces the number of characters required and makes it obvious what the thing is used for.

Changing the release packages to weave-gitops will have a negligible impact.
