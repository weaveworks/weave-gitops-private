# RFC-0003 How to detect deployment changes and to notify for pipeline promotions

<!--
The title must be short and descriptive.
-->

**Status:** provisional

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-10-05

**Last update:** 2022-10-05

## Summary

<!--
One paragraph explanation of the proposed feature or enhancement.
-->

Given a continious delivery pipeline is comprised of diffferent environments the application goes trough in
its way to production, there is need for an action to move the application among environments. That concept is known as
promotion and it is a one of the core concepts of a pipelines domain.

This RFC looks at different designs for notifying that a deployment has happened in order to trigger a promotion (if needed). 

## Terminology

- **Pipeline**: a continuous delivery Pipeline declares a series of environments through which a given application is expected to be deployed.
- **Promotion**: action of moving an application from a lower environment to a higher environment within a pipeline. 
For example promote stating to production would attempt to deploy an application existing in staging environment to production environment.
- **Environment**: An environment consists of one or more deployment targets. An example environment could be “Staging”.
- **Deployment target**: A deployment target is a Cluster and Namespace combination. For example, the above “Staging” environment, could contain {[QA-1, test], [QA-2, test]}.
- **Application**: A Helm Release.

## Motivation

<!--
This section is for explicitly listing the motivation, goals, and non-goals of
this RFC. Describe why the change is important and the benefits to users.
-->


This RFC looks at different designs for notifying that a deployment has happened in order to trigger a promotion (if needed).


### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->

- Discover different solutions within weave gitops that would allow to solve the problem of how to detect that
a deployment pipeline has changed.
- Recommend the one that seems better suited for the role. 

### Non-Goals

<!--
What is out of scope for this RFC? Listing non-goals helps to focus discussion
and make progress.
-->
- Anything related to processing the deployment notification.

## Comparison

<!--
This is where we get down to the specifics of what the proposal actually is.
This should have enough detail that reviewers can understand exactly what
you're proposing, but should not include things like API designs or
implementation.

If the RFC goal is to document best practices,
then this section can be replaced with the actual documentation.
-->


### Watchers approach

This approach suggests the creation of [kubernetes watchers](https://kubernetes.io/docs/reference/using-api/api-concepts/#efficient-detection-of-changes) 
per remote cluster. Each watcher would get notified whenever a Helm release in the remote cluster changes 
and take an action to start the next promotion based on the Pipeline definition.

[Tracking issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/1481)

#### Sequence diagram

```mermaid
   sequenceDiagram
    actor U as operator
    U->>+API Server: creates Pipeline
    participant PC as Pipeline Controller
    participant PS as Promotion Strategy
    API Server->>+PC: notifies
    participant dt1 as dev/target 1
    
    rect rgb(67, 207, 250)
    note right of PC: setup phase
    note right of PC: pipelines.wego.weave.works/name<br/>pipelines.wego.weave.works/env<br/>pipelines.wego.weave.works/target
    PC->>+dt1: label AppRef with metadata
    participant dt2 as dev/target 2
    PC->>+dt2: label AppRef with metadata
    participant pt1 as prod/target 1
    PC->>+pt1: label AppRef with metadata
    end
   
    rect rgb(50, 227, 221)
    note right of PC: promotion phase
    PC-->>+dt1: watches HelmRelease and Kustomizations changes
    PC-->>+dt2: watches HelmRelease and Kustomizations changes
    PC-->>+pt1: watches HelmRelease and Kustomizations changes
    end


    dt1->>+PC: update events from AppRef
    PC ->>PC: filter upgrade events 
    PC ->>PC: extract metadata 
    PC->>+PS: kicks off
  ```

#### Advantages

1. Plug n play: no further configurations or setup is needed to get updates.
1. Simple authentication: No need to worry about who triggered the event, since we are talking directly with the target.


#### Disadvantages and Mitigations

1. Requires Flux on all leaf clusters.
1. Scalability is unclear, we don't know the threshold at which the controller will be able to handle without issues.
1. There is no way to kick off promotions externally 

### Alert approach

This approach suggests the use of Flux [notification controller](https://fluxcd.io/flux/components/notification/) running on the remote cluster. 
An [alert](https://fluxcd.io/flux/components/notification/alert/) / [provider](https://fluxcd.io/flux/components/notification/provider/) 
would be setup to call a webhook running on the management cluster to notify a Helm release change in a remote cluster.

[Tracking issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/1487)


#### Sequence diagram

```mermaid
  sequenceDiagram
    actor U as operator
    U->>+API Server: creates Pipeline ns1/p1
    participant PC as Pipeline Controller
    participant PS as Promotion Strategy
    API Server->>+PC: notifies
    participant dt1 as dev/target 1
    rect rgb(67, 207, 250)
    note right of PC: alerting setup phase
    PC->>+dt1: creates Provider /ns1/p1/dev
    PC->>+dt1: creates Alert
    participant dt2 as dev/target 2
    PC->>+dt2: creates Provider /ns1/p1/dev
    PC->>+dt2: creates Alert
    participant pt1 as prod/target 1
    PC->>+pt1: creates Provider
    PC->>+pt1: creates Alert
    end
    rect rgb(50, 227, 221)
    note right of PC: promotion phase
    dt1->>+PC: sends Event to /ns1/p1/dev
    PC->>+PS: kicks off
    PS->>+pt1: promotes app
    end
  ```

#### Example Event

```json
{
  "involvedObject": {
    "kind": "HelmRelease",
    "namespace": "flux-system",
    "name": "metallb",
    "uid": "57c3579b-42da-4f27-afc5-8bd7778286e1",
    "apiVersion": "helm.toolkit.fluxcd.io/v2beta1",
    "resourceVersion": "155540"
  },
  "severity": "info",
  "timestamp": "2022-09-13T16:01:01Z",
  "message": "Helm upgrade succeeded",
  "reason": "info",
  "metadata": {
    "revision": "0.13.4",
    "summary": "foobar"
  },
  "reportingController": "helm-controller",
  "reportingInstance": "helm-controller-7cdc7874f8-9qpft"
}
```

#### Advantages

1. Simplicity: Uses Flux functionality as much as possible
2. Flexibility: Promotion can be kicked off from external systems by calling the webhook
3. Flexibility: Promotion can be exercised by an external system

#### Disadvantages and Mitigations

1. Requires Flux on all leaf clusters. _Mitigations: ?_
2. Authenticity of events needs to be taken care of. 
_Mitigations: add authentication and authorization to the webhook; verify event by reaching out to leaf cluster_
4. Network connectivity from all leaf clusters to management cluster necessary. 
_Mitigations: promotion can be kicked from any external system so if using notification-controller would not work, 
an external CI system could trigger promotion instead._

#### Known Unknowns

1. How does p-c set the correct Provider address?
   2. Configuration (user burden)
   3. Automatic determination (might get complicated quick to account for the different environments (with/without Ingress, external LB, ...)
2. How does p-c create the Provider/Alert resources? If it creates them directly by going through the target clusters' 
API server then it doesn't have a way of making sure they don't get modified/deleted (owner references don't work cross-cluster). 
Having them be committed to Git can be very complicated as the controller would have to know (1) wich Git repository to commit them to, 
(2) in wich location to put them, (3) if there's a `kustomization.yaml` that would have to be patched. 
An alternative could be to use a [remote Kustomization](https://fluxcd.io/flux/components/kustomize/kustomization/#remote-clusters--cluster-api) 
and the management cluster's Git repository.

#### Further Considerations

##### delivery semantics/failure scenarios recovery for notifications

The notification-controller is using [rate limiting](https://fluxcd.io/flux/components/notification/options/) that's 
only configurable globally with a default of 5m. This might lead to events not being emitted to the webhook.

notification-controller has [at-most once delivery semantics](https://github.com/fluxcd/notification-controller/tree/main/docs/spec#events-dispatching-1):

> The alert delivery method is at-most once with a timeout of 15 seconds. The controller performs automatic retries for 
> connection errors and 500-range response code. If the webhook receiver returns an error, the controller will retry 
> sending an alert for four times with an exponential backoff of maximum 30 seconds.

#### enrichment of events for custom metadata

The [Alert spec](https://fluxcd.io/flux/components/notification/alert/) allows for custom metadata to be added to events
by means of the `.spec.summary` field. The content of this field will be added to the event's `.metadata` map with the key "summary".