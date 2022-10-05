# 13. Pipelines - How to detect deployments

## Status
Proposed

## Context
As part of weave gitops, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) where
[first iteration has been delivered](https://docs.gitops.weave.works/docs/next/enterprise/pipelines/intro/index.html)
covering the ability to view an application deployed across different environments.

The [second iteration](https://www.notion.so/weaveworks/Pipeline-promotion-061bb790e2e345cbab09370076ff3258) aims 
to enable promotions between environments. 

As part of the promotions capabilities, there is the need to detect when a deployment has occurred with not only 
an approach to do it. During the discovery of the second iteration, two models has been spiked:

Detect deployment changes via

- [Watching](https://github.com/weaveworks/weave-gitops-enterprise/issues/1481)
- [Alert](https://github.com/weaveworks/weave-gitops-enterprise/issues/1487)

## Decision

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

As mentioned in the decision, the following consequences of the decision 

- A path forward for pipelines to deliver promotions capability. Sunglow could deliver promotions based on this approach.
- A risk to manage in the context of customer adoption: the network path opened. Sunglow would need to establish the customer feedback 
loop with SAs/CXs to manage and mitigate the risk once it happens. Same for security
- A scenario further to develop: existing CI scenarios based on the approach. Sunglow would need to use customer feedback to 
determine which existing systems are of relevance to provide the integration experience.  



