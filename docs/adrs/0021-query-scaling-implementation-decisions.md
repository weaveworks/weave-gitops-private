# 21. Query Scaling Implementation Decisions 

Date: 2023-08-18

## Status

Accepted

## Context

[Tangerine team](https://www.notion.so/weaveworks/Team-Tangerine-f70682867c9f4264ada9b678584e89cf?pvs=4) is working on
scaling multi-cluster querying [initiative](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4)
also known by Explorer. It was designed under [this RFC](../rfcs/0004-query-scaling). During its implementation 
we took different decisions that drifted from the original direction. 

This ADR records them with its motivation and other context information that might be relevant. 

## Decision

### Collector 

#### Watching

Collection uses [watching](https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes) 
instead of polling, as well as leveraging [controller-runtime](https://github.com/kubernetes-sigs/controller-runtime) machinery 
to have a more efficient (reduced latency to receive updates), reliable (include fault-tolerant mechanism) and simpler approach (already
abstracted high-level functionality available).

#### Authentication and Authorization

In order to watch clusters, we need to authenticate and authorise against the remote kubernetes api.  Collector 
follows the same approach as Weave Gitops of leveraging impersonation to manages its security context. It impersonates 
a collector service account that indicates the resources that collector can watch in remote clusters. 

### Authorization (RBAC) 

Authorization for Explorer was implemented by watching RBAC resources via Collector, and as indicated in the RFC,
doing authorization at query response time, filtering each object. Whilst this is custom business logic, the authorization 
business logic is leveraged to Kubernetes [rbac implementation](https://github.com/weaveworks/weave-gitops-enterprise/blob/462584c6c1882e1f190be8e4301e2bb7ffe9379d/pkg/query/rbac/rbac.go#L53)
to have, as close as possible, native Kubernetes semantics.

### Indexing

Given the limitations that searching based on sql-semantics imposes, Explorer was extended with [indexing component](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/pkg/query/store/indexer.go)
that incorporate the features that are expected in an indexing based search engine like full-text search.  

### Retention  

Initially Explorer was though a single cache to speed up load time and search experience. Since then, new use cases 
has been requested that have required extend the original design. Retention is one of them and has its own 
[ADR](0019-query-retention.md)

### Unstructured resources

As part of retention, but to support the ability to build up more flexible and targeted searching capability, 
explorer response includes, apart from the normalised object metadata (as stated in the original design), the 
resource representation in json. It enables UIs and other experiences to be created in the way that better suits the use case. 

## Consequences

- Anyone is able to build up a more complete understanding on Explorer implementation and design decisions.