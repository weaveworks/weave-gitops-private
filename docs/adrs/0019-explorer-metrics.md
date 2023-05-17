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

Following the same approach as OSS 
1) configuration flag to enable / disable metrics
2) Using same OSS library https://github.com/slok/go-http-metrics
3) Instrumenting the `/v1` api endpoint to get the metrics as done for OSS https://github.com/weaveworks/weave-gitops/blob/f69ed59f72e682330022dd7ce8217341944e0e8a/cmd/gitops-server/cmd/cmd.go#L268

```
# HELP http_request_duration_seconds The latency of the HTTP requests.
# TYPE http_request_duration_seconds histogram

http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.005"} 40532
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.01"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.025"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.05"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.1"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.25"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="0.5"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="1"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="2.5"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="5"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="10"} 40533
http_request_duration_seconds_bucket{code="200",handler="/",method="GET",service="",le="+Inf"} 40533
http_request_duration_seconds_sum{code="200",handler="/",method="GET",service=""} 7.091229956999948
http_request_duration_seconds_count{code="200",handler="/",method="GET",service=""} 40533


# HELP http_requests_inflight The number of inflight requests being handled at the same time.
# TYPE http_requests_inflight gauge
http_requests_inflight{handler="/",service=""} 0
http_requests_inflight{handler="/ProximaNovaBold.87676319.otf",service=""} 0
http_requests_inflight{handler="/ProximaNovaRegular.91a8c864.otf",service=""} 0
http_requests_inflight{handler="/ProximaNovaSemibold.7fa90ba1.otf",service=""} 0
http_requests_inflight{handler="/gitops-LOGO.4e557fcc.ico",service=""} 0
http_requests_inflight{handler="/index.21dc008b.js",service=""} 0


# HELP rest_client_request_duration_seconds Request latency in seconds. Broken down by verb, and host.
# TYPE rest_client_request_duration_seconds histogram
rest_client_request_duration_seconds_bucket{host="https://10.2.0.1:443/api/v1/namespaces/%7Bname%7D?timeout=30s",verb="GET",le="0.005"} 0
rest_client_request_duration_seconds_bucket{host="https://10.2.0.1:443/api/v1/namespaces/%7Bname%7D?timeout=30s",verb="GET",le="0.025"} 1
rest_client_request_duration_seconds_bucket{host="https://10.2.0.1:443/api/v1/namespaces/%7Bname%7D?timeout=30s",verb="GET",le="0.1"} 1
rest_client_request_duration_seconds_bucket{host="https://10.2.0.1:443/api/v1/namespaces/%7Bname%7D?timeout=30s",verb="GET",le="0.25"} 1
rest_client_request_duration_seconds_bucket{host="https://10.2.0.1:443/api/v1/namespaces/%7Bname%7D?timeout=30s",verb="GET",le="0.5"} 1
rest_client_request_duration_seconds_bucket{host="https://10.2.0.1:443/api/v1/namespaces/%7Bname%7D?timeout=30s",verb="GET",le="1"} 1

```

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

