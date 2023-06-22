# 19. Explorer Monitoring 

Date: 2023-06-XX

## Status

Proposed

## Context

[Tangerine team](https://www.notion.so/weaveworks/Team-Tangerine-f70682867c9f4264ada9b678584e89cf?pvs=4) is working on
scaling multi-cluster querying [initiative](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4)
also known by Explorer.

During Q1 we have worked on getting an initial functional iteration that validates we could solve the latency
and loading problems as part of [release v0.1](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4#270880bd0c4044c5b426eb0d8fb92faa).

In q2, we are looking to move towards a new [iteration v1.0](https://www.notion.so/weaveworks/Scaling-Weave-Gitops-Observability-Phase-3-7e0a1cfcc89641c9bb05a05c5356af34?pvs=4#d175338bd2004544ac8d52764ce26140)
to complete the solution and make ir production ready, where reliability is first-class concerns and monitoring.

In order to setup a direction that guides implementation we have worked in a vision. The working artifact is a miro 
board here https://miro.com/app/board/uXjVPiZGkZU=/?share_link_id=169655763202.

The outcome we used to drive the vision is enable a platform engineer to troubleshoot explorer issues using telemetry 
and monitoring artifacts provided.  

This ADR records that the major decisions out of that vision.

## Decision

I have two potential type of issues with some of its characteristics:

**Platform Issue**

- the issue is around one or multiple platform components.
- impacts a group of requests from different users.
- notified via alerting or multiple customer reporting failures.
- telemetry at the level of the components are required to follow the journey along the system.

**Request Issue**

- the error happens in the context of particular request, for example, from user with userId=123 or for payload=XYZ.
- usually notified via ticketing system as the customer is not able to do an action. 
- telemetry at the level of the transaction is required to follow the journey along the system.

### Troubleshooting platform issues 

#### Setup 

As platform engineer I have setup Explorer monitoring using the guidance in [explorer monitoring](https://docs.gitops.weave.works/docs/next/explorer/operations/#monitoring):

- I'm monitoring based on customer expectations, so I have setup Availability and Latency [SLOs](https://sre.google/workbook/implementing-slos/) as entry points. 
- I could see those SLOs as first row of the Explorer monitoring dashboard.
- I have also setup alerts based on error budget [burn rates](https://sre.google/workbook/alerting-on-slos/) in [Alert Manager](https://prometheus.io/docs/alerting/latest/alertmanager/)

I could find those resources as part of the [explorer monitoring](https://docs.gitops.weave.works/docs/next/explorer/operations/#monitoring) documentation

#### Troubleshooting an alert

Given The monitoring system has triggered an alert that translated in a ticket in my ticketing system. I have assigned the 
ticket and started troubleshooting. The alert has associated a runbook that indicates doing the following:

1. Go to explorer dashboard and see the SLOs in the first row.  Confirm the alerting event by seeing the impact in the burn rate. 
2. Go to the second row of the dashboard that shows you the Explorer querying path health: 
    - Verify [RED](https://www.weave.works/blog/the-red-method-key-metrics-for-microservices-architecture/) health metrics for Query API endpoint. 
    In case of not healthy, click here to troubleshoot.
   - Verify RED health metrics for Indexer reads. In case of not healthy, click here to troubleshoot.
   - Verify RED health metrics for Datastore reads. In case of not healthy, click here to troubleshoot.
3. Go to the third row of the dashboard that shows you the Explorer collecting path health:
   - Verify the health for the cluster watching infrastructure: check that metrics explorer_cluster_watchers_success_total == cluster_watchers_total.
   In case of not healthy, click here to troubleshoot.
   - Verify RED health metrics for cluster events processing: check that metrics explorer_cluster_event_success_total == cluster_watchers_total   //TODO review
   - Verify RED health metrics for Indexer writes. In case of not healthy, click here to troubleshoot.
   - Verify RED health metrics for Datastore writes. In case of not healthy, click here to troubleshoot.

### Troubleshooting request issues

Given that you have received a ticket indicating that an explorer user is not seeing the expected application. 
You have the details of the user and a screenshot that shows an empty explorer view.

As example:

```
curl 'https://demo3.weavegitops.com/v1/query' \
  -H 'authority: demo3.weavegitops.com' \
  -H 'cookie: id_token=abx' \
  -H 'origin: https://demo3.weavegitops.com' \
  -H 'pragma: no-cache' \
  -H 'referer: https://demo3.weavegitops.com/explorer/query' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36' \
  --data-raw '{"terms":"","filters":[],"limit":25,"offset":0,"orderBy":"","ascending":false}' \
  --compressed
```
with userId 

```
{
  "sub": "user@my-company.com",
  "exp": 1687426449,
  "nbf": 1687419249,
  "iat": 1687419249
}
```
In order to troubleshoot the request I follow the request runbook that says:

1. Retrieve from the access logs the requestId associated with the ticket by using `"sub": "user@my-company.com"`. It is requestId='123abc'. 
2. Check for specific errors: retrieve from the application logs if there has been any error with that transaction, for that you could filter by queries
like `level:error, requestId=123abc` around the time-window for the issue.  If you find error logs, find the error 
event in the troubleshooting knowledge base and continue with the steps indicated there.
3. Check for common errors: follow the knowledge base troubleshooting guide on common errors where you could find
how to troubleshoot common scenarios like missing permissions scenarios. 
// TODO review
4. In case not being able to determine the issue, try to replicate the query as the user with debug level and report it to support. 
3. Debug the request: you could debug for unknowns if you have your logLevel enabled to debug: `level:debug, requestId=123abc`


## Consequences

- Tangerine team aligns and knows what needs to implement in terms of telemetry to address the user monitoring concerns.
- A explorer user has covered its concerns by telemetry.
- Other engineering teams could leverage the approach for defining its own monitoring journeys. 
