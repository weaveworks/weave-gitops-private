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
- dedicated-environment for tenant. We have search-prod and billing-prod environments for running applications.
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
3. As search developer I want to create a pipeline using billing resources


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

We run the example using search with pipelines as

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

### RBAC configuration

Based on the existing ones
- [roles](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/user_roles.yaml)
- [role binding](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/admin_role_bindings.yaml)
- [documentation](https://docs.gitops.weave.works/docs/configuration/recommended-rbac-configuration/)

We need to have the following access requirements  
- developer to access pipeline resource namespace in management cluster
- developer to access environment clusters 
- developer to access application namespace within the clusters

We then need to create the following roles and roles bindings

- developer to access pipeline resource namespace in management cluster
- developer to access application namespace within the clusters

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: search-developer-pipeline-reader
  namespace: search
subjects:
  - kind: Group
    name: search-developer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pipelines-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: gitops-pipelines-reader
rules:
  - apiGroups: [ "pipelines.weave.works" ]
    resources: [ "pipelines" ]
    verbs: [ "get", "list", "watch" ]
  - apiGroups: ["kustomize.toolkit.fluxcd.io"]
    resources: [ "kustomizations" ]
    verbs: [ "get", "list", "patch" ]
  - apiGroups: ["helm.toolkit.fluxcd.io"]
    resources: [ "helmreleases" ]
    verbs: [ "get", "list", "patch" ]
```
and to allow impersonation from WGE backend to leaf cluster

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: impersonate-user-groups
subjects:
- kind: ServiceAccount
  name: ${serviceAccountName}
  namespace: ${serviceAccountNamespac}
roleRef:
  kind: ClusterRole
  name: user-groups-impersonator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: user-groups-impersonator
rules:
- apiGroups: [""]
  resources: ["users", "groups"]
  verbs: ["impersonate"]
- apiGroups: [""]
  resources: ["namespaces"]
  verbs: ["get", "list"]
````

- developer to access application namespace within the clusters

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-gitopsclusters
subjects:
  - kind: Group
    name: search-developer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: gitops-gitopsclusters-reader
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: gitops-gitopsclusters-reader
rules:
  - apiGroups: ["gitops.weave.works"]
    resources: ["gitopsclusters"]
    verbs: ["get", "watch", "list"]
```

### Access model by user story 

1. As search/billing developer I want to list or view a pipeline and its status (v0.1)

To view the pipeline 

- user clicks pipelines
- fe request to backend with
```
GET /v1/pipelines/search
Host: api.wge.com
Authorization: Bearer search-developer-jwt-token
```
- backend validates token 
- request forwarded to kube api  
```
GET /apis/pipelines.weave.works/v1alpha1/namespaces/search/pipeline/search
Host: kube.managmeent
Authorization: Bearer search-developer-jwt-token
```
- RBAC kicks in and will allow search-developer user access pipeline resources
- kube api returns search pipeline

And its status by environment, 

for example, to get dev status we 

get first the details for dev gitops cluster
```
GET /apis/GitopsCluster/dev
Host: kube.managmeent
Authorization: Bearer search-developer-jwt-token
```
with the kubeconfig, impersonate 

```
GET /apis/helm.toolkit.fluxcd.io/v2beta1/namespaces/search/helmreleases/search
Host: kube.dev
Authorization: Bearer dev-cluster-sa-with-impersonation
Impersonate-User: search-developer
```

3. As search developer I want to create a pipeline using billing resources

scenario 3a: billing pipeline created in search namespace

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: billing-shared-environment
  namespace: search
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
```

- I could create/view the pipeline cause I have access to search namespace or via gitops
- I could access dev cluster cause i have access to gitops clusters 
- I could impersonate user
- I cannot get helm releases in dev/billing as I have not access to that namespace
```
GET /apis/helm.toolkit.fluxcd.io/v2beta1/namespaces/billing/helmreleases/billing
Host: kube.dev
Authorization: Bearer dev-cluster-sa-with-impersonation
Impersonate-User: search-developer
```
scenario 3b: billing pipeline created in billing namespace

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
```
- I could create the pipeline via gitops
- I wont be able to view it as have not permissions to view pipelines in another namespace
- I wont be able to view status as have not access to billing namespace

### Scenario A - Recommendations
- use RBAC as indicated 
- create the namespaces structure in the management cluster 





and the api returns the helm release status as expected 




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
 




