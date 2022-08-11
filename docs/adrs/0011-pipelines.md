# 11. Continuous Delivery Pipelines in Weave GitOps

## Status

Approved

## Context

As part of weave gitops, Sunglow team is working on deliverying Continuous Delivery Pipelines based in the following 
[initiative](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a)

The past week has been used for doing discovery on designing a solution that could help us working in the context
of the two main milestones named as (0.1) and (1.0). 

The following three alternatives were defined and evaluated through [the following RFC](../rfcs/0001-pipelines/README.md) 

- [Pure label-based pipelines](https://github.com/weaveworks/weave-gitops-private/tree/737a2ec0181eaf52f9c0d6ea50b4915b9dd7844e/docs/rfcs/0001-pipelines#pure-label-based-pipelines)
- [Full CDR pipelines](https://github.com/weaveworks/weave-gitops-private/tree/737a2ec0181eaf52f9c0d6ea50b4915b9dd7844e/docs/rfcs/0001-pipelines#full-crd-based-pipelines)
- [Hybrid](https://github.com/weaveworks/weave-gitops-private/tree/737a2ec0181eaf52f9c0d6ea50b4915b9dd7844e/docs/rfcs/0001-pipelines#proposal)

And discussion was held [in-person and offline](https://github.com/weaveworks/weave-gitops-private/pull/54)  

## Decision

Pipelines implementation will start by using the `hybrid` solution and evolve the solution accordingly to emerging requirements
(if needed). This solution offers has been decided as it offers a balanced approach in terms of 
- simplicity: to start shipping towards 0.1 without the complexity that other solutions like `full crd` could impose in terms of machinery.   
- performance: provides a better query path experience than solutions like purely `label` alternative.
- flexible for the unknowns: it is flexible enough to reduce risks towards 1.0. 

We will be taking an enterprise-first strategy where first iteration will be 
on [weave gitops enterprise](https://github.com/weaveworks/weave-gitops-enterprise) for then upstream it to 
[weave gitops OSS](https://github.com/weaveworks/weave-gitops). We have decided to go in this direction to optimise 
for speed of delivery and availability of the capability for our users. Currently, existing architectural dependencies
between OSS and Enterprise translate in a sensible impact on the lead time when delivering via OSS.

## Consequences

To have an enterprise-first approach, has an impact on OSS users that won't see a delay on when the capability will be available.

To have an enterprise-first approach reduces risk to deliver against our main engineering objective of
[OKR#2: Add features that drive Weave GitOps enterprise customer conversion](https://docs.google.com/presentation/d/104b4ThKT78rznucxw6kMsrRY0OnEn6XanSvb039TA-g/edit#slide=id.gd1cb39726e_19_8)
