# 19. Explorer Monitoring 

Date: 2023-06-XX

## Status

Proposed

## Context

[Tangerine team](https://www.notion.so/weaveworks/Team-Tangerine-f70682867c9f4264ada9b678584e89cf?pvs=4) is working on
scaling multi-cluster querying [initiative](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4)
also known by explorer capability.

During q1 we have worked on getting an initial functional iteration that validates we could solve the latency
and loading problems as part of [release v0.1](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4#270880bd0c4044c5b426eb0d8fb92faa).

In q2, we are looking to move towards a new [iteration v1.0](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4#d175338bd2004544ac8d52764ce26140)
to complete the solution and make ir production ready, where reliability is first-class concerns and monitoring.

In order to setup a direction that guides implementation we have worked in a vision. The working artifact is a miro 
board here https://miro.com/app/board/uXjVPiZGkZU=/?share_link_id=169655763202.

This ADR records the major decisions out of that vision.

## Decision

The main user journey that we are covering with our monitoring vision is the ability, of a platform engineer, to
troubleshoot an issue of explorer using the monitoring and telemetry provided. 

For that, the platform engineer have setup its monitoring system using weave gitops guidance https://docs.gitops.weave.works/docs/next/explorer/operations/#monitoring
So:
- I have [two SLOs](https://sre.google/workbook/implementing-slos/) set for explorer service: availability SLO, latency SLO
- My monitoring entry layer is the dashboard provided by https://docs.gitops.weave.works/docs/next/explorer/operations/#monitoring
- I am altering based on error budget burn rates https://sre.google/workbook/alerting-on-slos/

The monitoring system has triggered an alert that ended up creating a ticket. The platform engineer starts troubleshooting by:

1. Going to the dashboard and seeing that the error budget is being impacted
2. It could understand whether there is an infrastructure problem in the querying path by looking at querying monitoring row that shows:
    - [RED](https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/) metrics for Query API endpoint. 
    - RED metrics for Indexer reads.
    - RED metrics for Datastore reads.
3. It could understand whether there is an infrastructure problem in the collection path by looking at collecting monitoring row that shows:
    - RED metrics for Query API endpoint.
    - RED metrics for Indexer writes.
    - RED metrics for Datastore writes.







## Consequences

- Tangerine team aligns and knows what needs to implement in terms of telemetry to address the user monitoring concerns.
- A explorer user has covered its concerns by telemetry.
- Other engineering teams could leverage the approach for defining its own monitoring journeys. 
