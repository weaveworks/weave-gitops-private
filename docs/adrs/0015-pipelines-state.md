# 15. maintain state for pipelines

## Status

Provisional

## Context
As part of Weave GitOps Enterprise, Sunglow is working on delivering [Continuous Delivery [Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) where the current iteration is to enable [manual promotions](https://www.notion.so/weaveworks/Manual-Promotions-6270cddd363648e08c259e671063aadf), which requires keeping track of the approval state. This ADR records the decision on which solution to explore around this problem.

## Decision

There are different alternatives to maintain the state. Some of them were explored
in the [discovery](https://miro.com/app/board/uXjVP9DpBjc=/?share_link_id=229323743612):

3. to hold state in the Pipeline CR status as Flagger does https://github.com/fluxcd/flagger/blob/main/pkg/apis/flagger/v1beta1/status.go#L70-L90
4. to hold state in a database as Spinnaker or Keptn does https://keptn.sh/docs/concepts/architecture/
5. to hold state in another CR as Tekton does between Pipeline and PipelineRuns https://tekton.dev/docs/pipelines/pipelineruns/
6. to use a Configmap
7. to use Pipeline CR metadata / annotations

The direction is to explore Pipeline CR status as an alternative because it is the most straightforward, natural
next step given the current understanding of the problem space.


The rest alternatives are de-prioritized due to the following reasons:

1. Configmap, Pipeline CR metadata are considered a variation of the same use case as the CR status but
with more limitations.
2. An external database was discarded at this stage for the operational overhead to maintain it without
clear benefit.
3. Another CR is discarded due to the need for maintenance costs while not yet having a clear
use case.


## Consequences

We might be limited by how we can structure the data and query, but as of now, we do not need anything complex. On the other hand, it should be straightforward to implement without adding any external dependency.
