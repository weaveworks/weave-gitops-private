# 13. Pipelines Promotions

## Status
Proposed

## Context
As part of weave gitops, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) where
[first iteration has been delivered](https://docs.gitops.weave.works/docs/next/enterprise/pipelines/intro/index.html)
covering the ability to view an application deployed across different environments.

The [second iteration](https://www.notion.so/weaveworks/Pipeline-promotion-061bb790e2e345cbab09370076ff3258) aims 
to enable promotions between environments. 

This ADR records a couple of decision we think are important:

- how the promotion solutions looks like end to end.
- how deployment changes are detected.

## Decision

### How promotions solution looks like end to end 

As [discussed in RFC](../rfcs/0003-pipelines-promotion/README.md) four alternatives were discussed:

- weave gitops backend
- pipelines controller
- weave gitops + pipeline controller  + promotion executor
- promotions service

The `pipeline controller` solution has been chosen over its alternatives (see alternatives section) due to

- it enables promotions.
- it allows to separations roles, therefore permissions between the components notifying the change and executing the promotion.
- it is easier to develop over other alternatives.

On the flip side, the solution has the following constraints:

- there is a need to manage and expose the endpoint for deployment changes separately to weave gitops api.
- non-canonical usage of controllers as its behaviour is driven by ingested event than change in the declared state of a resource.

### How deployment changes are detected

As [discussed in RFC](../rfcs/0003-pipelines-promotion/detect-deployment-changes.md) each of approaches has associated unknowns.

The major ones are:

- Webhooks: the need for a new network flow in the product, from leaf cluster to management, and the potential impediments
  that it would suppose for customers while adopting the solution, as well its security management.
- Watching: how reliable the solution could be as not having existing examples of products using it for watching remote clusters.

We envision weave gitops as  needs to be a flexible solution that eventually would need to support both approaches
to accommodate the range of potential enterprises using weave gitops.

In order to start with one of the approaches, we have decided to start by `webhooks` solution due to:

- Allow us to provide promotions for wge customers based on our own promotions capability with better scalability approach.
- Reinforces the vision of weave gitops being a continuum of Flux by using Flux core components, in this context, [notification
  controller](https://fluxcd.io/flux/components/notification/), to provide the basic building blocks around deployment notification.

## Consequences

- A path forward for pipelines to deliver promotions capability. Sunglow could deliver promotions based on this approach.
- A set of further actions needs to be risks that needs management:
  - To manage the risk associated with the network flow between leaf to management cluster for deployment notifications. 
  - To determine concrete CI scenarios that we need to integrate with.
  - To discover the reliability aspects of the watchers approach to understand its feasibility.


