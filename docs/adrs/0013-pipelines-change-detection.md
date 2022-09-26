# 13. Pipelines - How to detect deployment changes

## Status
Proposed

## Context
As part of weave gitops, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) 

It's [first version (v0.1)](//TODO add link) has been delivered covering the ability to view an application deployed across different environments.

The [second iteration](//TODO) aims to enable integration with internal and external promotions. 

As part of the promotions capabilities, there is the need to detect when a deployment has occurred with not only 
an approach to do it. During the discovery of the second iteration, two models has been spiked:

Detect deployment changes via

- [Watching](https://github.com/weaveworks/weave-gitops-enterprise/issues/1481)
- [Webhooks](https://github.com/weaveworks/weave-gitops-enterprise/issues/1487)

## Decision

As [discussed in RFC](../rfcs/0003-change-detection/README.md) each of approaches has associated unknowns. The major ones were

- Webhooks: the need for a new network flow in the product, from leaf cluster to management, and the impediments
  that it would suppose for customers while adopting the solution.
- Watching: how reliable the solution could be as not having existing examples of products using it for watching remote clusters.

We envision that weave gitops needs to be a flexible solution that eventually would need to support both approaches
to accommodate the range of potential enterprises using weave gitops. 

In order to start with one of the approaches, we have decided to start by using `webhooks` due to 

- allow us to provide promotions for wge customers based on our own promotions capability 

but also because

- flux provides the base building blocks to integrate with existing customer's promotion systems. It opens the door 
for a gradual adoption of the wge pipeline solution for customers that already have custom delivery logic.

## Consequences

As mentioned in the decision, the following consequences of the decision 

- A path forward for pipelines to deliver promotions capability. Sunglow could deliver promotions based on this approach.
- A risk to manage in the context of customer adoption: the network path opened. Sunglow would need to establish the customer feedback 
loop with SAs/CXs to manage and mitigate the risk once it happens. 
- A scenario further to develop: existing CI scenarios based on the approach. Sunglow would need to use customer feedback to 
determine which existing systems are of relevance to provide the integration experience.  



