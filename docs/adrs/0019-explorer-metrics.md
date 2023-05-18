# 19. Explorer Metrics 

Date: 2023-05-XX

## Status

Proposed

## Context

Tangerine team is working on scaling multi-cluster querying initiative https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4 
also known by explorer capability. 

During q1 we have worked on getting an initial functional iteration that validates we could solve the latency 
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

Following the same approach as OSS 
1) configuration flag to enable / disable metrics
2) Using same OSS library https://github.com/slok/go-http-metrics
3) Instrumenting the `/v1` api endpoint to get the metrics as done for OSS https://github.com/weaveworks/weave-gitops/blob/f69ed59f72e682330022dd7ce8217341944e0e8a/cmd/gitops-server/cmd/cmd.go#L268

An example of the metrics family are:

```
http_request_duration_seconds_bucket{code="200",handler="/v1/clusters",method="GET",service="",le="0.005"} 0
http_request_duration_seconds_bucket{code="200",handler="/v1/config",method="GET",service="",le="0.005"} 0
...
http_request_duration_seconds_bucket{code="200",handler="/v1/query",method="POST",service="",le="0.05"} 0
http_request_duration_seconds_sum{code="200",handler="/v1/query",method="POST",service=""} 10.088081923
http_request_duration_seconds_count{code="200",handler="/v1/query",method="POST",service=""} 51
```
where we could take the golden signals from, and we could [dashboard](./resources/dashboard.json) as usual via grafana
![explorer-metrics.png](images%2Fexplorer-metrics.png)

## Metrics for Collection 

//TODO 

## Consequences

TBA 

