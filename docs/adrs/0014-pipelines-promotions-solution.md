# 13. Pipelines Promotions

## Status
Proposed

## Context
As part of weave gitops, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) where
[first iteration has been delivered](https://docs.gitops.weave.works/docs/next/enterprise/pipelines/intro/index.html)
covering the ability to view an application deployed across different environments.

The [second iteration](https://www.notion.so/weaveworks/Pipeline-promotion-061bb790e2e345cbab09370076ff3258) aims 
to enable promotions between environments. 

Once defined how to [detect a deployment change](0013-pipelines-detect-deployments.md), this ADR defines 
how the solution e2e looks in terms of architecture.

## Decision

As [discussed in RFC](../rfcs/0003-pipelines-promotion/promotions-solution.md) four alternatives were discussed:

- Alternative A: weave gitops backend
- Alternative B: pipelines controller
- Alternative C: new service called promotions service
- Alternative D: cluster services + pipeline controller  + promotion executor

From the alternatives, promotions solution would be implemented using 
alternative B, pipelines controller, as

//TODO


## Consequences

As mentioned in the decision, the following consequences of the decision 

- A path forward for pipelines promotions e2e.



