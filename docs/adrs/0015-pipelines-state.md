# 15. maintain state for pipelines

## Status

Accepted

## Context
As part of Weave GitOps Enterprise, Sunglow is working on delivering [Continuous Delivery Pipelines](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a) 
where the current iteration is to enable [manual promotions](https://www.notion.so/weaveworks/Manual-Promotions-6270cddd363648e08c259e671063aadf), 
which requires keeping track of the approval state. 

This ADR records the decision on which solution to explore around this problem.

## Decision

There are different alternatives to maintain the state. Some of them were explored
in the [discovery](https://miro.com/app/board/uXjVP9DpBjc=/?share_link_id=229323743612):

1. to hold state in the Pipeline CR status as [Flagger does](https://github.com/fluxcd/flagger/blob/main/pkg/apis/flagger/v1beta1/status.go#L70-L90)
2. to hold state in a database as Spinnaker or [Keptn does](https://keptn.sh/docs/concepts/architecture/)
3. to hold state in another CR as [Tekton does](https://tekton.dev/docs/pipelines/pipelineruns/) between Pipeline and PipelineRuns 
4. to use a Configmap
5. to use Pipeline CR metadata / annotations

The direction is to explore **Pipeline CR status** as an alternative because it is the most straightforward, natural
next step given the current understanding of the solution space.

The rest alternatives are de-prioritized due to the following reasons:

1. Configmap, Pipeline CR metadata are considered a variation of the same use case as Pipeline CR status but
with more limitations like external resource (configmap) or less structured data (annotations).
2. An external database was discarded at this stage for the operational overhead to maintain it without
clear need at this stage.
3. Another CR is discarded due to the need for maintenance costs while not yet having a clear
use case.

## Consequences

We might be limited by how we can structure the data and query, but as of now, we do not need anything complex. 
On the other hand, it should be straightforward to implement without adding any external dependency.

It has been envisioned that for complex scenarios an evolution from CR status to other more sophisticated
solution might be required. At this stage, we cannot envision major future risks doing so. This decision should be 
reviewed then.
