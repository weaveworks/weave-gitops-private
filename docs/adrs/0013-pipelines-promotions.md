# 13. Pipelines Promotions

## Status
Proposed

## Context
As part of Weave GitOps Enterprise, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) where
[first iteration has been delivered](https://docs.gitops.weave.works/docs/next/enterprise/pipelines/intro/index.html)
covering the ability to view an application deployed across different environments.

The [second iteration](https://www.notion.so/weaveworks/Pipeline-promotion-061bb790e2e345cbab09370076ff3258) aims 
to enable promotions between environments. 

This ADR records a couple of decisions we think are important:

- how the promotion solution looks like end to end.
- how deployment changes are detected.

## Decision

### How the promotion solution looks like end to end 

As [discussed in RFC](../rfcs/0003-pipelines-promotion/README.md) four alternatives were discussed:

- weave gitops backend
- pipelines controller
- weave gitops + pipeline controller  + promotion executor
- promotions service

The `pipeline controller` solution has been chosen over its alternatives (see alternatives section) due to

- It enables promotions.
- It allows to separations roles, therefore permissions between the components notifying the change and executing the promotion.
- It follows [notification controller pattern](https://fluxcd.io/flux/guides/webhook-receivers/#expose-the-webhook-receiver).
- It is easier to develop over other alternatives.
- It keeps split user-experience and machine-experience apis.

On the flip side, the solution has the following constraints:

- Need to manage another api surface.
- Non-canonical usage of controllers as its behaviour is driven by ingested event than change in the declared state of a resource.
  - We accept this tradeoff as pipeline controller provides us with a balanced approach between tech-debt and easy to start delivering
    over other alternatives (like creating another component).

### How deployment changes are detected

As [discussed in RFC](../rfcs/0003-pipelines-promotion/detect-deployment-changes.md) each approach has associated unknowns.

The major ones are:

- Webhooks: the need for a new network flow in the product, from leaf cluster to management, and the potential impediments that it would suppose for customers while adopting the solution, as well its security management.
- Watching: how reliable the solution could be as not having existing examples of products using it for watching remote clusters.

We envision Weave GitOps will need to offer a flexible solution, and would eventually support both approaches
to accommodate the range of potential enterprise users.

In order to optimise velocity, we are starting with one approach - the `webhooks` solution due to:

- It allows us to provide promotions for WGE customers with suspected better scalability.
- Reinforces the vision of weave gitops being a continuum of Flux by using Flux core components, in this context, [notification
  controller](https://fluxcd.io/flux/components/notification/), to provide the basic building blocks around deployment notification.
- Leverages existing, tried-and-tested functionality from Flux to reduce amount of new functionality we need to write.
- Team is taking on responsibilities for Flux primitives, which includes Notification Controller related objects, and therefore presents a good opportunity to improve the UX for working with this capability.

## Consequences

- A path forward for pipelines to deliver promotions capability. Sunglow could deliver promotions based on this approach.
- A set of further actions needs to be risks that needs management:
  - To manage the risk associated with the network flow between leaf to management cluster for deployment notifications. 
  - To determine concrete CI scenarios that we need to integrate with.
  - To discover the reliability aspects of the watchers approach to understand its feasibility.


