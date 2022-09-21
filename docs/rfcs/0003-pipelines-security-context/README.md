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

Scenario: 

We have two tenants
- `search`  that provides the apps for discoverability within the orgs business model
- `billing` that provides customer billing related capabilities for the orgs business model

And we have two types of organisations

- org-shared-environments where we have a single dev, staging prod environmentn for running all applications
- tenant-segmented where we have  search-prod and billing-prod environments for running applications

Both organisation are using pipelines for wge with 
- tenants for search and billing
- clusters managed by WGE

The user stories that we want to run through is that

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
- search pipeline exists 
- billing pipeline exists
Dev, Staging, Prod: 
- search  app deployed as helm release in each of the environment 
- billing app deployed as helm release in each of the environment

Search Pipeline
```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: search-shared-environment
  namespace: default
spec:
  appRef:
    kind: HelmRelease
    name: search
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: dev
      targets:
        - namespace: dev
          clusterRef:
            kind: GitopsCluster
            name: dev
            namespace: flux-system
    - name: staging
      targets:
        - namespace: staging
          clusterRef:
            kind: GitopsCluster
            name: staging
            namespace: flux-system
    - name: prod
      targets:
        - namespace: prod
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
  namespace: default
spec:
  appRef:
    kind: HelmRelease
    name: billing
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: dev
      targets:
        - namespace: dev
          clusterRef:
            kind: GitopsCluster
            name: dev
            namespace: flux-system
    - name: staging
      targets:
        - namespace: staging
          clusterRef:
            kind: GitopsCluster
            name: staging
            namespace: flux-system

    - name: prod
      targets:
        - namespace: prod
          clusterRef:
            kind: GitopsCluster
            name: prod
            namespace: flux-system
```

### RBAC configuration 

Using existing ones
[role binding](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/admin_role_bindings.yaml)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: wego-admin-read-pipelines
subjects:
- kind: User
  name: "wego-admin"
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: gitops-pipelines-reader
  apiGroup: rbac.authorization.k8s.io
```
[roles](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/user_roles.yaml)
```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gitops-pipelines-reader
  labels:
    {{- include "mccp.labels" . | nindent 4 }}
    {{- if .Values.rbac.userRoles.roleAggregation.enabled }}
    rbac.authorization.k8s.io/aggregate-to-gitops-reader: "true"
    {{- end }}
rules:
- apiGroups: ["pipelines.weave.works"]
  resources: ["pipelines"]
  verbs: ["get", "list", "watch"]
{{- end }}
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
Host: kube.api
Authorization: Bearer search-developer-jwt-token
```
- request forwarded to kube api

RBAC kicks and will allow search-developer access if it has access to pipeline resource 



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
 




