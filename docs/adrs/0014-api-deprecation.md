# 13. weave gitops api deprecation policy 

## Status

Proposed

## Context

Weave gitops leverages different api layers within the product. Therefore, as part of the natural evolution of the 
product, the apis are expected to evolve so a management of its lifecycle is required. As part of this lifecycle, 
a strategy for deprecation is required in place to setup a sensible contract that allow 

- developer to have a mechanism to evolve their apis
- customers to have stability enough to adopt these changes

This ADR defines an initial api deprecation strategy for weave gitops based on the following kubernetes  resources: 
 
- Kubernetes api deprecation policy https://kubernetes.io/docs/reference/using-api/deprecation-policy/
- Kubernetes crd versioning https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/
- Kubernetes api migration guide https://kubernetes.io/docs/reference/using-api/deprecation-guide/

## Decision

### Guidelines 

We follow as guidelines the [kubernetes api deprecation policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/#deprecating-parts-of-the-api)

**Versioning**

We follow the same 3 main tracks

- v1, GA (generally available, stable)
- v1beta1, Beta (pre-release)
- v1alpha1,	Alpha (experimental)

**Rule #1: API elements may only be removed by incrementing the version of the API group.**

- No refinement or exceptions identified 
 
**Rule #2: API objects must be able to round-trip between API versions in a given release without information loss, 
with the exception of whole REST resources that do not exist in some versions.**

- No refinement or exceptions identified

**Rule #3: An API version in a given track may not be deprecated in favor of a less stable API version.**

- No refinement or exceptions identified

**Rule #4a: API lifetime is determined by the API stability level**

Refined to use number of releases instead of months as better suits our context.

- GA API versions may be marked as deprecated, but must not be removed within a major version of Kubernetes.
- Beta API versions are deprecated no more than 3 minor releases after introduction, 
and are no longer served 3 minor releases after deprecation.
- Alpha API versions may be removed in any release without prior deprecation notice.

Exceptions 

- GA apis could be removed in XXX 


**Rule #4b: The "preferred" API version and the "storage version" for a given group may not advance 
until after a release has been made that supports both the new version and the previous version**

- No refinement or exceptions identified

### Communicating Api changes

API Changes should be communicated as part of the https://docs.gitops.weave.works/docs/enterprise/releases/
including references on how to migrate. A reference in this space is the [kubernetes migration guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

## Consequences

TBA



