# 15. maintain state for pipelines   

## Status

Provisional

## Context
As part of Weave GitOps Enterprise, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) where
current iteration is to enable [manual promotions](https://www.notion.so/weaveworks/Manual-Promotions-6270cddd363648e08c259e671063aadf) which 
requires to keep track on the approval state. This ADR records the decision on which solution to explore around this problem. 

## Decision

There are different alternatives in order to maintain state. Some of them were explored 
in the [discovery](https://miro.com/app/board/uXjVP9DpBjc=/?share_link_id=229323743612) :

//TODO add references

3. to hold state in the Pipeline CR status as Flagger does
4. to hold state in a database as Spinnaker or Keptn does
5. to hold state in another CR as Tekton does between Pipeline and PipelineRuns https://tekton.dev/docs/pipelines/pipelineruns/
6. to use a Configmap
7. to use Pipeline CR metadata / annotations

The direction is to explore Pipeline CR status as alternative because it seems the simplest, natural 
next step given the current understanding of the problem space.


The rest alternatives are de-prioritised due to the following reasons:

1. Configmap, Pipeline CR metadata are considered a variation of the same use case as the CR status but 
with more limitations.
2. External database discarded as this stage for the operational overhead to maintain it without 
clear benefit. 
3. Another CR is discarded due to the need to maintainance costs while not having yet a clear 
use case for it. 


## Consequences

TBA




