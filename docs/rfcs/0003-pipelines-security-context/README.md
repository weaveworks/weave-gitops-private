# RFC-0003 pipelines security for weave gitops enterprise multi-tenancy

**Status:** provisional
**Creation date:** 2022-09-29

## Summary

This rfc proposes the security posture required for pipelines to securily work in a weave gitops enterprise multi-tenant environment.   

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


## Scenario A: shared environments

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





2. As search/billing developer,I want to be able to promote apps via pipelines for my tenant (v0.2)
    1. promotions via watching
    2. promotions via webhook

Assumed promotions via webhook, promotion would happen via pipeline controller that would raise a PR against the
configuration repo. In order to raise the PR it requires

1. from deployment event, to understand the environment, resource and version promoted. 
2. from the pipeline crd, to understand the next environment to promote.
3. from the helm release source, to understand the details and strategy to promote (for example raise PR for helm release in github). 
4. access to the source for raising the PR to promote (for example github).

Pipeline controller would then require for 2) and 3)  
- in management 
- and leaf clusters
something like the following RBAC

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

For 4) it would require target github access within tenancy boundaries meaning that we set guarantees 
that promotions for search does not have any risk for billing. 

Solutions should go into honour those boundaries like for example creating promotion job bounded to tenant 
where the job only have access to the search configuration, search sources and secrets (ephimeral ideally). 

   
3. As platform admin, I want to ensure by design an isolated experience between tenants.

For developers, we have two points to control
- creation or admission of resources or
- runtime or usage of these resources via 

For creation scenario, we should just ensure that no resources are created outside the boundaries of the tenant that 
we could achieve via pipeline policies at admission time. A couple of examples are shown below

scenario 3a: pipeline to be created violating tenancy via namespace

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: tenancy-violated-pipeline
  namespace: search
  annotations:
    tenancy: billing
spec:
  xxxx
```

scenario 3b: pipeline referencing resources from other tenant

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: serach-pipeline-using-billing-resources
  namespace: search
  annotations:
    tenancy: search
spec:
  appRef:
    kind: HelmRelease
    name: search
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

both pipelines should be rejected according to the tenancy rules 

### Scenario A Summary

- Tenancy should be extended to create the right rbac and policies that will ensure the security context of the previous journeys.
- Pipeline controller promotions should be designed with the isolation principles in mind. 

## Scenario B: tenancy by environment

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

Given the previous definition, a pipeline for search-svc would look like

```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: search-tenancy-by-environment
  namespace: search # important
  annotations:
    tenancy: search
spec:
  appRef:
    kind: HelmRelease
    name: search
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

### Policy Configuration 

//TODO add a policy that assigns access to a set of clusters via policy 

### RBAC configuration

Based on the existing ones
- [roles](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/user_roles.yaml)
- [role binding](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/templates/rbac/admin_role_bindings.yaml)
- [documentation](https://docs.gitops.weave.works/docs/configuration/recommended-rbac-configuration/)

We need to have the following access requirements
- developer to access pipeline resource
- developer to access environment clusters
- developer to access application namespace within the clusters

We then need to create the following roles and roles bindings

- developer to access pipeline and cluster resources in management
- developer to access application namespace within the clusters

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

### Access model by user story

1. As search/billing developer,I want to create a pipeline for my tenant (v0.1)

we create the following pipeline
```yaml
apiVersion: pipelines.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: search-tenancy-by-environment
  namespace: search # important
  annotations:
    tenancy: search
spec:
  appRef:
    kind: HelmRelease
    name: search
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
that during admission time will be validated based on policies so no tenancy boundaries will be respected:
- pipeline is created within the tenant namespace 
- using the allowed apps
- using the allows clusters 

2. As search/billing developer I want to list or view a pipeline and its status (v0.1)

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

the pipeline and its status is available to the user  

3. As search/billing developer,I want to be able to promote apps via pipelines for my tenant (v0.2)

There are no different considerations from this scenario to the tenancy by namespace for the pipeline controller

3. As platform admin, I want to ensure by design an isolated experience between tenants.

- Policies checking tenancy domain should be good enough to ensure isolation at admission time
- Right RBAC at runtime would complement user access  


### Scenario B Summary

Similar to Scenario A with the addition that given that we have a new tenancy dimension: the cluster, we should 
check permissions at that level
- via policies for pipelines at creation (priority)
- via RBAC on the gitops cluster resource at runtime. This is not neccesarily a super priority
as if the tenant would not have access, it would not have been created. 




### Summary, recommendations and further questions 


1. As search/billing developer,I want to create a pipeline for my tenant (v0.1)

- We need to create the policies to validate references of pipeline, appRef and clusterRef






- better access control to gitops clusters is required
- in case cluster belongs to a tenant, then the manifest should be created
  withing that namespace in the cluster management
- in the context of pipelines apis and controller, once we have a reference to a resources
  - cluster or applications, we should check whether we have access to it, otherwise fail
  - we could do this via policies as admission or at runtime
- we should leverage policies more! in particular cause we could easily assume that
  will exist within the management cluster




2. As search/billing developer,I want to view pipelines for my tenant(v0.1)

Tenancy By Namespace

Tenancy By Cluster
- We need some semantics to define rules for tenant cluster access. 
- Two approaches are possible within wge
  - via RBAC 
  - via Policy
The proposal shows both but potentially the policy approach sounds better 
  
3. As search/billing developer,I want to be able to promote apps via pipelines for my tenant (v0.2)

Tenancy By Namespace

**pipeline controller** 
TBD 
- we should impersonate or grant pemissions for access resources
- impersonation should happen in the context of the event
- we could also no use impersonation and to grant permissions

**for promotions and pipeline controller, given that we need to access the repo, how
do we ensure by design that only the right credentials are used? Here the potential solution
is to create tenant jobs on demand bounded to the tenant. And the token to be potentially ephemeral.

Tenancy By Cluster 


3. As platform admin, I want to ensure by design an isolated experience between tenants.

Recommendations

- Extend tenancy to create the suggested RBAC configuration for pipelines. 
- Extend tenancy to create the suggested policies for admission. 

Tenancy By Namespace

- Create policies that only allow admission of resources for a tenant within their 
tenancy boundaries. in this case the namespace.

Tenancy By Cluster

- Create policies that only allow admission of resources for a tenant within their
  tenancy boundaries. in this case the cluster.


### Limitations 

We have pictured tenancy as an static concern but not discussed when a tenant is being modified











- 
 




