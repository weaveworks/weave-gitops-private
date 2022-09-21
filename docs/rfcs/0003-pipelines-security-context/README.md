# RFC-0003 Pipelines security context

<!--
The title must be short and descriptive.
-->

**Status:** provisional

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-07-29

**Last update:** 2022-08-25

## Summary

Define the security context where pipelines would live one. We just want to ensure that we have a proper security 
approach for pipelines from the 
- user perspective
- platform perspective

## Motivation

Revisiting [pipelines rfc](../0001-pipelines/README.md) to extend security consideration

>* **what happens if I create a Pipeline refering to a non-existing Namespace or cluster?** The Pipeline's `.status` field reflects the status of each referenced cluster. 
>* However, it will not reflect any state of remote resources on one of these clusters. Therefore, a cluster that's not reachable from the pipeline-controller or a non-existing
>* Namespace on that cluster referred to by a `Pipeline` is not visible in the `Pipeline` resource itself.

1. Pipelines enables delivering apps to environments.
2. Environments could span different deployment targets.  
3. Deployment targets has a defined access model given by either RBAC or Tenancy. 

This RFC goes into ensure that pipelines provides good security properties for users and platform 


### Terminology

TBA


### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->
- Define security model for pipeline users.
- Define security model for pipeline components.

### Non-Goals

<!--
What is out of scope for this RFC? Listing non-goals helps to focus discussion
and make progress.
-->

* Automatic promotion of an application through the stages of a pipeline is not part of this proposal but the proposal should allow for building that on top.

## Proposal

### Scenario 

We have two **tenants**
- `search`  that provides the apps for discoverability within the orgs business model
- `billing` that provides customer billing related capabilities for the orgs business model

And two tenancy models

- shared-environments with tenancy by namespace. 
  - environments: dev, staging and prod 
  - namespaces: search and billing
- dedicated-environment for tenannt. We have search-prod and billing-prod environments for running applications.
  - environments: search-prod, billing-prod
  - namespaces: not relevant

Both scenarios will be using WGE so 
- pipelines would be in management clusters
- applications will run in leaf clusters 

**User stories** that we want to run through is that

1. As search/billing developer I want to list or view a pipeline and its status (v0.1)
   1. as pipeline ui,
      1. I want to access `list pipelines ` or
      2. `get pipeline` endpoint
   2. as pipeline backend,
      1. I want to access to pipelines resources in management cluster by <pipeline namespace, pipeline name>
      2. I want to access the underlying helm release resources in deployment target by <helm release name, target deployment cluster, target deployment namespace>
2. As search/billing developer I want to have promotions in my pipeline done via wge (v0.2)
   1. promotions via watching  
   2. promotions via webhook
3. As search/billing developer I cannot view/create pipelines over resources I have no access to


## Scenario A: shared environment

Management Cluster:
- search namespace
  - search pipeline exists
- billing namespace 
  - billing pipeline exists
Environments (Dev, Staging, Prod): 
- search namespace
  - search helm release exists
- billing namespace
  - billing helm release exists

Search Pipeline
```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: search-shared-environment
  namespace: search
spec:
  appRef:
    kind: HelmRelease
    name: search
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: dev
      targets:
        - namespace: search
          clusterRef:
            kind: GitopsCluster
            name: dev
            namespace: flux-system
    - name: staging
      targets:
        - namespace: search
          clusterRef:
            kind: GitopsCluster
            name: staging
            namespace: flux-system
    - name: prod
      targets:
        - namespace: search
          clusterRef:
            kind: GitopsCluster
            name: prod
            namespace: flux-system
```

Billing Pipeline
```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: billing-shared-environment
  namespace: billing
spec:
  appRef:
    kind: HelmRelease
    name: billing
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: dev
      targets:
        - namespace: billing
          clusterRef:
            kind: GitopsCluster
            name: dev
            namespace: flux-system
    - name: staging
      targets:
        - namespace: billing
          clusterRef:
            kind: GitopsCluster
            name: staging
            namespace: flux-system
    - name: prod
      targets:
        - namespace: billing
          clusterRef:
            kind: GitopsCluster
            name: prod
            namespace: flux-system
```

### RBAC configuration

Based on the existing ones
- [roles](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/user_roles.yaml)
- [role binding](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/admin_role_bindings.yaml)
- [documentation](https://docs.gitops.weave.works/docs/configuration/recommended-rbac-configuration/)

We need to have the following access requirements  
- developer to access management cluster for pipeline namespace
- developer to access environment clusters 
- developer to access application namespace within the a
- search and billing to access dev, staging and prod clusters
- within that cluster to access to namespace that the application has access


We create the following RBAC configuration for the scenario that allows

- any developer to access any  
- given 
- 



We start by the following permissions

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-pipelines-reader
subjects:
  - kind: Group
    name: developer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pipelines-reader
  apiGroup: rbac.authorization.k8s.io
```

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gitops-pipelines-reader
  labels:
    { { - include "mccp.labels" . | nindent 4 } }
      { { - if .Values.rbac.userRoles.roleAggregation.enabled } }
      rbac.authorization.k8s.io/aggregate-to-gitops-reader: "true"
      { { - end } }
rules:
  - apiGroups: [ "pipelines.weave.works" ]
    resources: [ "pipelines" ]
    verbs: [ "get", "list", "watch" ]
  { { - end } }
```


### Access model by user story 

1. As search/billing developer I want to list or view a pipeline and its status (v0.1)
- user clicks pipelines
- fe request to backend with
```
GET /pipelines
Host: api.wge.com
Authorization: Bearer search-developer-jwt-token
```
- backend validates token 
- request forwarded to kube api  
```
GET /pipelines
Host: api.kube.managmeent
Authorization: Bearer search-developer-jwt-token
```
- request forwarded to kube api

RBAC kicks in and will allow search-developer user access pipeline resources if 

- search-developer has 



If the user is ``

Given that there isno



- ui access token identify  
   1. as pipeline ui,
      1. I want to access `list pipelines` or
      2. `get pipeline` endpoint
   2. as pipeline backend,
      1. I want to access to pipelines resources in management cluster by <pipeline namespace, pipeline name>
      2. I want to access the underlying helm release resources in deployment target by <helm release name, target deployment cluster, target deployment namespace>
3. As search/billing developer I want to have promotions in my pipeline done via wge (v0.2)
   1. promotions via watching
   2. promotions via webhook
4. As search/billing developer I cannot view/create pipelines over resources I have no access to





## Scenario B: segmentation by tenant 

In the context of the first scenario we have the three stories are 






- 
 




