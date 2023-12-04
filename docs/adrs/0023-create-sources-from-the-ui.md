# 23. Create Flux sources from the UI

Date: 2023-11-06

## Status

Accepted

## Context

Weave GitOps Enterprise (WGE) does not currently support the creation of Flux sources (GitRepository, HelmRepository, OCIRepository etc.) through the UI. 

## Decision

We will enable the creation of Flux sources in the WGE UI by replicating the functionality offered by the [Flux CLI](https://fluxcd.io/flux/cmd/flux_create_source/). 

This means that the UI will make no attempt to additionally create secrets that are referenced by the Flux sources being created. Instead, the user will be asked to enter the name of a secret in the Create source UI form, that the source will reference.


## Consequences

The decision to forgo secret creation means that users that create sources that reference secrets, will need to create those secrets prior to creating a source that relies on them. Although this is not an ideal workflow, it is still worth doing for the following reasons:
- Not all sources will be referencing secrets, examples of such sources are public Helm repositories of popular tools or when workload identity is configured.
- The proposed solution does not preclude us from enhancing this feature later to also create secrets (possibly via the use of ExternalSecrets)