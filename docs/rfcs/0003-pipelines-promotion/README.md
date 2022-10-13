# RFC-0003 Pipeline promotions 

**Status:** provisional

**Creation date:** 2022-10-xx

**Last update:** 2022-10-xx

## Summary

Given a continuous delivery pipeline, the application goes via different environments on its way to production. We 
need an action to signal the intent of deploying an application between environments. That concept is generally known as a
promotion. Current pipelines in weave gitops does not support promotion. This RFC addresses this gap 
as specified in the [product initiative](https://www.notion.so/weaveworks/Pipeline-promotion-061bb790e2e345cbab09370076ff3258)

## Terminology

- **Pipeline**: a continuous delivery Pipeline declares a series of environments through which a given application is expected to be deployed.
- **Promotion**: action of moving an application from a lower environment to a higher environment within a pipeline.
  For example promote staging to production would attempt to deploy an application existing in staging environment to production environment.
- **Environment**: An environment consists of one or more deployment targets. An example environment could be “Staging”.
- **Deployment target**: A deployment target is a Cluster and Namespace combination. For example, the above “Staging” environment, could contain {[QA-1, test], [QA-2, test]}.
- **Application**: A Helm Release.

## Motivation

Given a continuous delivery pipeline, the application goes via different environments in its way to production. We
need an action to sign the intent of deploying an application between environments. That concept is generally known as a
promotion. Current pipelines in weave gitops does not support promotion. 

### Goals

- Design the e2e solution for promotions on weave gitops pipelines.
- Should support the [scenarios identified](https://www.notion.so/weaveworks/Pipeline-promotion-061bb790e2e345cbab09370076ff3258#5b514ad575544595b1028d73e5b6dd23) 

### Non-Goals

- Anything beyond the scope of promotions.
- Scenarios other than the identified in the product initiative.

## Proposal
We propose to use a solution as specified in the following diagram. 

```mermaid
   sequenceDiagram
    participant F as Flux
    participant LC as Notification Controller (Leaf)
    F->>LC: deploy helm release
    LC->>pc: send deployment change event
    participant pc as Pipeline Controller (Managment)
    pc->>pc: authz and validate event
    participant k8s as Kubernetes Api
    pc->>k8s: get pipeline
    pc->>pc: promotion business logic
    participant k8s as Kubernetes Api
    pc->>configRepo: raise PR
    participant configRepo as Configuration Repo
```

With three main activities

1. Detect deployment changes
2. Determine whether a promotion is needed  
3. Execute the promotion 

### Detect deployment changes

The solution leverages [flux native notification capabilities](https://fluxcd.io/flux/components/notification/) for this responsibility.
Notification controllers in leaf clusters would notify of deployment events to the management cluster via 
a deployment webhook. The management cluster will ingest and validate these deployment events. 

A deeper look into this part of the solution could be found [here](detect-deployment-changes.md).

### Determine whether a promotion is needed

This responsibility is assumed by the `pipeline controller` running in the management cluster that: 
- determine whether at the back of the event and a pipeline definition, a promotion is required. 

A deeper look into this part of the solution could be found [here](determine-promotion-needs.md).

### To execute the promotion

Once the previous evaluation considers that a promotion is required, pipeline controller would be in charge 
of orchestrating and executing the task according to its configuration.

A deeper look into this part of the solution could be found [here](execute-promotion.md).


### Why this solution

The current solution has been chosen over its alternatives (see alternatives section) due to

- It enables promotions.
- It allows to separations roles, therefore permissions between the components notifying the change and executing the promotion.
- It follows [notification controller pattern](https://fluxcd.io/flux/guides/webhook-receivers/#expose-the-webhook-receiver).
- It is easier to develop over other alternatives.
- It keeps split user-experience and machine-experience apis.

On the flip side, the solution has the following constraints:

- Platform operators needs to manage another api surface, in this case, the `promotion webhook` endpoint.
- Non-canonical usage of controllers as its behaviour is driven by ingested event than change in the declared state of a resource.
  - We accept this tradeoff as pipeline controller provides us with a balanced approach between tech-debt and easy to start delivering
  over other alternatives (like creating another component).

## Alternatives

This solution is the result of two different alternative evaluations:
1. Alternatives to detect deployment changes. 
2. Alternatives to process and execute promotions.

### Alternatives to detect deployment changes.

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

#### Evaluation

**Advantages**

1. Plug n play: no further configurations or setup is needed to get updates.
1. Simple authentication: No need to worry about who triggered the event, since we are talking directly with the target.

**Disadvantages and Mitigations**

1. Requires Flux on all leaf clusters.
2. Scalability is unclear, we don't know the threshold at which the controller will be able to handle without issues.
3. There is no way to kick off promotions externally

### Alternatives to process and execute promotions.

They difference among them is around 
the component serving the promotion logic, therefore the alternatives names are based on it.

- Alternative A: weave gitops backend
- Alternative B: weave gitops api + pipeline controller  + promotion executor
- Alternative C: promotions service (new service)

#### Alternative A: weave gitops backend

```mermaid
   sequenceDiagram
    participant F as Flux
    participant LC as Notification Controller (Leaf)
    F->>LC: deploy helm release
    LC->>wge: send deployment change event
    participant wge as Weave Gitops Backend (Managment)
    wge->>wge: authz and validate event
    participant k8s as Kubernetes Api
    wge->>k8s: get pipeline
    wge->>wge: promotion business logic
    participant k8s as Kubernetes Api
    wge->>configRepo: raise PR
    participant configRepo as Configuration Repo
```

This solution is different from `pipeline controller` in that the three responsibilities: 

1. Notify deployment changes
2. Determine whether a promotion is needed
3. Execute the promotion

are fulfilled within weave gitops backend app.

**Pro**
- Already setup and *should* be more easily exposed. 
- No need to manage other exposed surface, therefore less to secure.

**Cons**
- Notifier service account needs permissions for promotion resources.
- Current api layer is designed as an experience layer for users (humans) while the promotion webhook is intended for machines.
- Extends the api layer with rest api so it would require to manage both grpc and rest apis that would increase maintainability costs.  


#### Alternative B: weave gitops api + pipeline controller  + promotion executor

```mermaid
   sequenceDiagram
    participant F as Flux
    participant LC as Leaf Cluster
    F->>LC: deploy helm release
    LC->>WGE: notify deployment via notification controller    
    participant WGE as Weave Gitops API
    participant k8s as Kubernetes Api
    WGE->>k8s: write deployment event
    participant pc as pipeline controller
    k8s->>pc: watch deployment event & pipelines
    pc->>pj: create promotion job
    participant pj as promotion job
    pj->>pj: promotion business logic
    pj->>configRepo: raise PR
    participant configRepo as Configuration Repo
```

This solution is different from `pipeline controller` in that the three responsibilities are split

1. Notify deployment changes: ingestion is done via weave gitops api. The event is written in pipeline resource. 
2. Determine whether a promotion is needed: pipeline controller watches for changes in pipeline.
3. Execute the promotion: extracted to a kubernetes job layer. 

**Pro**
- Using ingestion layer so not increased operational costs.  
- No need to generate TS client
- Pipeline controller with reconcile loop so canonical usage. 
- Scalability and fault-tolerance by design.

**Cons**
- Needs for writing the pipeline resource.
- The most complex alternative. 
- To extract the promotion execution logic into an external component, would require to also create a management layer 
between pipeline controller to the execution layer. 

#### Alternative C: promotions service

This solution would be to create a new component with the promotions responsibility. 

```mermaid
   sequenceDiagram
    participant F as Flux
    participant LC as Notification Controller (Leaf)
    F->>LC: deploy helm release
    LC->>PS: notify deployment via notification controller    
    participant PS as Promotions Svc (Management)
    PS->>PS: authz and validate event
    participant k8s as Kubernetes Api
    PS->>k8s: get pipeline
    PS->>PS: promotion business logic
    participant k8s as Kubernetes Api
    PS->>configRepo: raise PR
    participant configRepo as Configuration Repo
```
**Pro**
- Easiest to dev against (vs api solution).
- No controller so no reconcile loop executed (vs pipeline controller solution). 

**Cons**
- Ee would need to create it from scratch. 
- One more component to manage. 

## Design Details

### Pipeline spec changes for promotions

In order to accommodate promotion logic, the pipeline spec would be extended with a `promotion` field as shown below

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: podinfo
  namespace: default
spec:
  appRef:
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    name: podinfo
    #used for hmac authz - this could change at implementation 
    secretRef: my-hmac-shared-secret 
  promotion:
    pullRequest:
      url: https://github.com/organisation/gitops-configuration-monorepo.git
      branch: main
      secretRef: my-gitops-configuration-monorepo-secret #contains the github token to clone and create PR   
  environments:
  - name: dev
     targets:
     - namespace: podinfo
        clusterRef:
          kind: GitopsCluster
          name: dev
```
The promotion field used to capture the promotion tasks for the next environment in the pipeline after a successful deployment has taken place.
Each task will include the following fields:

- `name`: the task name
- `type`: the task type, either webhook or pull-request
- `url` : the git repository url or the webhook url
- `branch`: the branch to use for the update, defaults to main (only applicable when kind is pull-request)
- `secretRef`: a reference to a secret in the same namespace as the pipeline that holds the authentication credentials for the repository or the webhook.

## Implementation History

- [Promotions Issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/1589)