# 14. weave gitops api versioning and lifecycle guidelines 

## Status

Accepted

## Context

Weave gitops leverages different api layers within the product. Therefore, as part of the natural evolution of the 
product, the apis are expected to evolve so a management of its lifecycle is required. As part of this lifecycle, 
a strategy for managing different versions is required to set sensible contract that allows 

- any weave gitops developer to have a mechanism to evolve the product to meet business needs. 
- any weave gitops customers to have stability enough to adopt these changes with guarantees.

This ADR defines an initial api versioning and deprecation strategy for weave gitops, based on existing kubernetes approach, 
with the refinements considered to match our context. The baseline resources for it has been 

From Weave Gitops Enterprise
- [Weave GitOps Service Description ENv2.0](https://docs.google.com/document/d/1s1m8cRf2Ut2fTOdLbbooaddCh6tlq-wpYIY7ElBf9QA)

From Kubernetes

- [Kubernetes api versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning)
- [Kubernetes api deprecation policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/)
- [Kubernetes crd versioning](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/)
- [Kubernetes api migration guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

## Decision

### Versioning  

We follow kubernetes [api versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning) taken at this 
[moment](https://github.com/kubernetes/website/commit/d308cbb35a335a5eb34ef4a7fb8a20ea1b98d100). 

We also consider the definition of Recent Version within weave gitops enterprise service description 

>Recent Version: A recent version of any software would typically include the current version and the previous 2 versions.  
> If there is a Long Term support version the latest Long Term support version and the previous 2 versions.

#### Stable

- The version name is vX where X is an integer (for example, v1).
- Considered as Long Term supported version within weave gitops enterprise service definition. 
- Stable API versions do not have a maximum lifetime from introduction to deprecation.
- Stable API versions could be deprecated and removed.  
- Stable API versions do have 3 months or 6 releases (whichever is longer) from deprecation to removal.

#### Beta

- The version names contain beta (for example, v2beta3).
- Beta API versions do not have a maximum lifetime from introduction to deprecation. 
- Beta API versions do have 2 months or 4 releases (whichever is longer) from deprecation to removal.
- Using a feature is considered safe.
- The support for a feature will not be dropped, though the details may change.
- The software is not recommended for production uses. Subsequent releases may introduce incompatible changes. 
  Use of beta API versions is required to transition to subsequent beta or stable API versions once the beta API version is deprecated and no longer served.

#### Alpha

- The version names contain alpha (for example, v1alpha1).
- The software may contain bugs. 
- Support for an alpha API may be dropped at any time without notice.
- The API may change in incompatible ways in a later software release without notice.
- The software is recommended for use only in short-lived testing clusters, due to increased risk of bugs and lack of long-term support.

### Deprecation

We also are influenced by [kubernetes api deprecation policy](https://kubernetes.io/docs/reference/using-api/deprecation-policy/)

**Rule #1: API elements may only be removed by incrementing the version of the API group.**

**Rule #2: API objects must be able to round-trip between API versions in a given release without information loss, 
except for whole REST resources that do not exist in some versions.**

**Rule #3: An API version in a given track may not be removed in favor of a less stable API version.**

This rule refines original one to allow, for example, to deprecate stable api versions in favour of beta api versions but
do not remove until a stable or long term supported api version exists. 

It is also to refine that any removal of apis should comply with the definition of a **Recent Version** that indicates
that three versions: recent and two previous should be supported at any time. This has the exception to new components where
there are less than three versions in total.

**Rule #4a: API lifetime is determined by the API stability level**

**Rule #4b: The "preferred" API version and the "storage version" for a given group may not advance 
until after a release has been made that supports both the new version and the previous version**

### Notifying API changes

API Changes should be communicated as part of the [release notes](https://github.com/weaveworks/weave-gitops-enterprise/releases) and 
available in the [documentation](https://docs.gitops.weave.works/docs/enterprise/releases/). 

Examples of the information to provide could be found in [kubernetes migration guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

### Supporting migration 

In order to support a customer migrating apis:

- Expected timelines should be communicated.  
- Migration instructions should be provided. They might include editing or re-creating API objects. It might not be straightforward or including downtime.
- It is encouraged to provide how to test or get ready for the migration before it happens.  
- When there is significant impact to customers by the change, tooling to support the migration effort is recommended.
- Two main approaches for this tooling:
  1. To provide [conversion hooks](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/#webhook-conversion)
  2. To provide tooling that allow conversion of files within git.
- Given our context, to provide tooling for converting in git is preferred as addresses the conversion at the source.


### Exceptions 

If you are not able to meet these guidelines, please discuss with product engineering leadership for an exception. 


## Consequences

- Weave gitops apis should align its lifecycle to the direction indicated here.
- Given that we are not having the same context as kubernetes, this document is expected to evolve to adapt 
  those indications that increase our costs without providing clear benefits. 



