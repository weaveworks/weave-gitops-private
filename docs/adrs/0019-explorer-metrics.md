# 19. Explorer Metrics 

Date: 2023-05-XX

## Status

Proposed

## Context

Tangerine team is working on scaling multi-cluster querying initiative https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4 
also known by explorer capability. 

During q1 we have worked on getting an initial functional interation that validates we could solve the latency 
and loading problems as part of release v0.1 https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4#270880bd0c4044c5b426eb0d8fb92faa

In q2 we are looking to move towards a new iteration 1.0 to complete the solution and make ir production ready https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4#d175338bd2004544ac8d52764ce26140
Where reliability is first-class concerns and observability and metrics as part of it. This ADR writes the 
direction we are tacking to address metrics for observability for explorer. 

## Decision

Given the Explorer architecture defined here https://github.com/weaveworks/weave-gitops-enterprise/blob/add-search-architecture-docs/docs/architecture/explore.md 

We have two main path: querying and collecting that we need to monitor. 

## Metrics for Querying

It is a sync request/response driven system that we could monitor by its [golden signals](https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals):
In particular the regular latency, rate, errors and saturation. At this stage we will calculate from the api server serving 
the request and using the search endpoints https://github.com/weaveworks/weave-gitops-enterprise/blob/main/api/query/query.proto

// missing the how

// i am expecting that from https://docs.gitops.weave.works/docs/references/helm-reference/#values metrics enabled + adding some metrics
// we need to poc this

## Metrics for Collection 

Collection is a workflow in three stages that we want to monitor:
- watching resource events
- process or reconcile the events
- write them to the correct remote store

these three stages shoudl be monitor as follow

### watching resource events

Based on kubernetes watching api server we could monitor it via default controller-runtime metrics

//TODO define which ones

### process or reconcile the events

once the event has been received it is then queued for processing, the queing and processing could be monitored
by metrics provided too by controller-runtime

//TODO define which ones

### write them to the correct remote store

last step is to store in the right targets that could be monitor based on their clients 

//TODO define which ones

// authz store client metrics 
// index client metrics



## Consequences

