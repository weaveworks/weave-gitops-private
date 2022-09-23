# RFC-0003 pipelines security for weave gitops enterprise multi-tenancy

**Status:** provisional
**Creation date:** 2022-09-29

## Summary

This rfc proposes the security posture required for pipelines to securely work in a weave gitops enterprise multi-tenant environment.   

## Motivation

[pipelines rfc](../0001-pipelines/README.md) indicates the approach to use to define a delivery pipeline to deliver 
an application across multiple environments.

Weave Gitops Enterprise will host multiple applications owned by multiple teams being delivered across multiple environments. 
That multi-tenancy nature, and how to keep the isolation between tenant to ensure that any of them could use 
pipelines safely is the main goal of this RFC.

### Terminology

- **Application**: A Helm Release.
- **Pipeline**: A CD Pipeline declares a series of environments through which a given application is expected to be deployed.
- **Environment**: An environment consists of one or more deployment targets. An example environment could be “Staging”.
- **Promotion**: action to relase an application from a lower environment into a higher enviroment in the context of delivery pipelines.
- **Deployment target**: A deployment target is a Cluster and Namespace combination. For example, the above “Staging” environment, could contain {[QA-1, test], [QA-2, test]}.
- **Multi-tenancy**: ability to serve a multiple group of users in an isolated manner using a shared environment.  
  For this proposal we could assume that a platform running WGE is the shared environment and all the application teams are the user group.
- **Tenant**: each of the groups using services from the platform. For this proposal we could just assume that an application team is tenant.

### Goals

- Define the security guidelines for pipelines to be used in a multi-tenant environment. 

### Non-Goals

TBA 

## Proposal

### Assumptions 

- An organisation uses WGE. Multiple application teams conform the organisation.
- Each team within the organisation is a tenant.
- Isolation between tenants is a requirement.  
- Tenancy is implemented via [WGE tenancy capabilities](https://www.notion.so/weaveworks/Tenant-Workspaces-Abstracted-RBAC-d16b58f8dd89498ea7a1f792440185fc)

### Scenario 

For the proposal we are going to use the following scenario. 

**Organisations by Tenancy models**
We are going to define two organisation, each one with a different tenancy model.
- `shared-environments` where tenants are isolated at the level of the namespace. Each tenant owns a namespace within each environment/cluster. 
- `dedicated-environments` where tenants are isolated at the level of the environment. Each tenant owns an entire cluster. 

**Tenants**
- `search` that provides searching capabilities for the org. 
- `billing` that provides billing capabilities for the org.

**Pipelines**
Both organisations uses WGE pipelines as pipelines delivery capability so   
- pipelines CRD are hosted in the management cluster
- applications run in leaf clusters 

**User stories** 
To consider in the context of this proposal  

1. As search/billing developer,I want to create a pipeline for my tenant (v0.1)
2. As search/billing developer,I want to view a pipeline for my tenant (v0.1)
3. As search/billing developer,I want to promote apps via pipelines for my tenant (v0.2)
4. As platform admin, I want to ensure by design an isolated experience between tenants.

## Scenario A: shared environments, tenancy by namespace

### Tenancy Definition 
Environments: 
- Dev, Staging and Prod
Tenants:
- Search tenant has access to only search namespace in any environment 
- Billing tenant has access to only tenant namespace in any environment

### Tenant Resources Allocation
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

### Security requirements by user story 

#### As search/billing developer,I want to create a pipeline for my tenant (v0.1)

The requirements for a pipeline to be valid in the context of its tenancy model is that 

- A pipeline is created within a tenant namespace.
- A pipeline references applications that the tenant can use. 
- A pipeline references clusters that a tenant can use. 

Given the previous definition, 

A valid pipeline for search-svc could look like

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: valid-search-shared-environment
  namespace: search
spec:
  appRef:
    kind: HelmRelease
    name: search-svc
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: prod
      targets:
        - namespace: search
          clusterRef:
            kind: GitopsCluster
            name: prod
            namespace: flux-system
```

An invalid pipeline for search-svc could look like

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: invalid-search-shared-environment
  namespace: billing #invalid pipeline namespace
spec:
  appRef:
    kind: HelmRelease
    name: billing #invalid app
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: prod
      targets:
        - namespace: billing #invalid app namespace
          clusterRef:
            kind: GitopsCluster
            name: prod
            namespace: flux-system
```
Therefore, to ensure that only valid pipelines are created, it will require to validate the pipeline resource 
at admission time to ensure that the requirements are met. 

//TODO: add the policies that will honor these requirements 

#### As search/billing developer,I want to view pipelines for my tenant (v0.1)

To view the pipeline via WGE UI a user clicks in pipeilnes therefore the following request is generated
```
GET /v1/pipelines/search
Host: api.wge.com
Authorization: Bearer search-developer-jwt-token
```
WGE backend validated the token and forwards the request to kube api 
```
GET /apis/pipelines.weave.works/v1alpha1/namespaces/search/pipeline/search
Host: kube.managmeent
Authorization: Bearer search-developer-jwt-token
```
Kube api wil authorise it based on RBAC and the search developer will retrieve the resource. 

In order to compute the pipeline status, queries will be done to the leaf cluster, for example in dev 
it would be something similar to 

```
GET /apis/helm.toolkit.fluxcd.io/v2beta1/namespaces/search/helmreleases/search
Host: kube.dev
Authorization: Bearer dev-cluster-sa-with-impersonation
Impersonate-User: search-developer
```
For the previous flow to work we would need to meet the following Authz requirements 

- developer to access pipeline resource namespace in management cluster
- developer to access environment clusters
- developer to access application namespace within the clusters

That based on the existing ones 
- [roles](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/user_roles.yaml)
- [role binding](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/admin_role_bindings.yaml)
- [documentation](https://docs.gitops.weave.works/docs/configuration/recommended-rbac-configuration/)

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

And a developer to access application namespace within the clusters

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

#### As search/billing developer,I want to be able to promote apps via pipelines for my tenant (v0.2)

Assumed promotions via webhook, promotion would happen via pipeline controller that would raise a PR against the
configuration repo. 

In order to raise the PR, a pipeline controller component requires 

1. from deployment event, to understand the environment, resource and version promoted. 
2. from the pipeline crd, to understand the next environment to promote.
3. from the helm release source, to understand the details and strategy to promote (for example raise PR for helm release in github). 
4. access to the source for raising the PR to promote (for example github).

To achieve

>2. from the pipeline crd, to understand the next environment to promote.
>3. from the helm release source, to understand the details and strategy to promote (for example raise PR for helm release in github).
 
something like the following RBAC is required

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pipeline-controller
subjects:
  - kind: ServiceAccount
    name: pipeline-controller
    namespace: flux-system
roleRef:
  kind: ClusterRole
  name: pipeline-controller
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pipeline-controller
rules:
  # model A a via impersonation
  - apiGroups: [""]
    resources: ["users", "groups"]
    verbs: ["impersonate"]
  # model B a via granted permissions
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

To achieve 

>4. access to the source for raising the PR to promote (for example github).

It would require to target github access within tenancy boundaries meaning that promotions for search does not have any risk for billing. 

Different solutions could be at this regard but the one proposed would be
- promotion jobs
- configured just for the context of the event / tenant
- using ephemeral auditable access tokens
   
#### As platform admin, I want to ensure by design an isolated experience between tenants.

It is achieved by the union of the three previous stories. 

## Scenario B: tenancy by dedicated environments

### Tenancy Definition
Tenants:
- Search tenant has access to environments within their tenancy. 
- Billing tenant has access to environments within their tenancy.
Environments: dev, staging production
Clusters:
- search-dev, search-staging and search-prod clusters
- billing-dev, billing-staging and billing-prod clusters

### Tenancy Resource Allocation 

We simplify the environments / cluster to just production

Management Cluster:
given that we need to have pipelines in the management we create isolation based on the tenant with  
- search namespace
    - search pipeline exists
    - search-prod gitops cluster exists
    - search-pipeline-clusters policy exists 
- billing namespace
    - billing pipeline exists 
    - billing-prod gitops cluster exists
Clusters:
- search-prod
    - search-svc helm release exists in any namespace
- billing-prod
    - billing helm release exists in any namespace
### Security requirements by user story

#### As search/billing developer,I want to create a pipeline for my tenant (v0.1)

The requirements for a pipeline to be valid in the context of its tenancy model is that

- A pipeline is created within a tenant namespace.
- A pipeline references applications that the tenant can use.
- A pipeline references clusters that a tenant can use.

A valid pipeline for search-svc could look like

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: valid-search-dedicated-environment
  namespace: search
spec:
  appRef:
    kind: HelmRelease
    name: search-svc
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: prod
      targets:
        - namespace: any-namespace
          clusterRef:
            kind: GitopsCluster
            name: search-prod
            namespace: search # important
```

An invalid pipeline for search-svc could look like

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: valid-search-dedicated-environment
  namespace: search
spec:
  appRef:
    kind: HelmRelease
    name: search-svc
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
  environments:
    - name: prod
      targets:
        - namespace: any-namespace
          clusterRef:
            kind: GitopsCluster
            name: billing-prod
            namespace: billing # important
```
Same as previous scenario, we would need to validate at admission time that the resources coudl be created

//TODO add a policy that assigns access to a set of clusters via policy 


#### As search/billing developer I want to list or view a pipeline and its status (v0.1)

given the pipeline from previous story, a developer wants to view it via the UI

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

And its status by environment, for example, to get production status:

- we get first the details for dev gitops cluster
```
GET /apis/namespaces/search/gitopscluster/search-production
Host: kube.managmeent
Authorization: Bearer search-developer-jwt-token
```
that returns the secret with the kubeconfig to retrieve and impersonate
and the developer could view the helm release via impersonation
```
GET /apis/helm.toolkit.fluxcd.io/v2beta1/namespaces/search/helmreleases/search
Host: kube.search-production
Authorization: Bearer search-production-cluster-sa-with-impersonation
Impersonate-User: search-developer
```
Same as the previous scenario, we will address this problem via RBAC creating the following 


For management cluster
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: search-developer-management
  namespace: search
subjects:
  - kind: Group
    name: search-developer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: developer-management
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-management
rules:
  - apiGroups: ["gitops.weave.works"]
    resources: ["gitopsclusters"]
    verbs: ["get", "watch", "list"]
  - apiGroups: [ "pipelines.weave.works" ]
    resources: [ "pipelines" ]
    verbs: [ "get", "list", "watch" ]
```

For leaf cluster

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: search-developer-leaf
subjects:
  - kind: Group
    name: search-developer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer-leaf
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-leaf
rules:
  - apiGroups: [ "helm.toolkit.fluxcd.io" ]
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

#### As search/billing developer,I want to be able to promote apps via pipelines for my tenant (v0.2)

There are no different considerations from this scenario to the tenancy by namespace for the pipeline controller

#### As platform admin, I want to ensure by design an isolated experience between tenants.

It is achieved by the union of the three previous stories.

### Summary, recommendations and further questions

Existing WGE capabilities provides the foundations to ensure the righ security level for pipelines. The 
usage of policies and RBAC should provide good balanace in terms of security for WGE tenants.

In particular by user story we have the following recommendations

1. As search/billing developer,I want to create a pipeline for my tenant (v0.1)

To leverage policies to validate pipelines at admission time. Validation would cover pipeline, appRef and clusterRef.

2. As search/billing developer,I want to view pipelines for my tenant(v0.1)

To leverage RBAC to ensure users have the right permission for via pipeline and its status. 

3. As search/billing developer,I want to be able to promote apps via pipelines for my tenant (v0.2)

Pipeline controller would require 
- RBAC to access pipeline and flux primitives  
- Multi-tenant github access for promotion logic. As the example indicated in the proposal 
  - promotion jobs
  - configured just for the context of the event / tenant
  - using ephemeral auditable access tokens


### Limitations 

We have pictured tenancy as an static concern but not discussed when a tenant is being modified











- 
 




