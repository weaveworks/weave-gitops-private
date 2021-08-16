# 7. Directory Layout

Date: 2021-08-16

## Status

Accepted

## Context

The current directory structure introduces a new term "target", doesn't support environment customizations, doesn't provide a solution for application versions, and creates a tight coupling between applications (apps) and clusters. We require a new layout in order to addess these items.

We thought a FAQ would be useful in describing the context for these changes.

### Glossary 
* **Appplication** a collection of kubernetes manifests. Stored in /apps
* **Cluster** a kubernetes cluster.  Stored in clusters/&lt;name&gt;
* **Environment** a configuration of an application that can be applied to one or more clusters.  Stored in apps/&lt;name&gt;/env
* **Profile** a package containing kubernetes manifests, helm charts, and/or other profiles.  Stored in  /profiles

### FAQ
**Q. I have a few manifests, what's the easiest way to deploy them?**

**A.** Commit your manifests in clusters/&lt;name&gt;/user directory and they will be deployed to the cluster

**Q. I want to keep my manifests in a repo other than the Weave GitOps repo?**

**A.** When adding your application, Weave GitOps will create a source and kustomize resource under the name of your app in /apps.  

**Q. I have environment kustomizations for my application manifests which live in a differnt repo?**

**A.** Using wego, you will create a new environment under your application name.  These will contain a kustomize resource definition that refers to the path in your remote repo containing the kustomization.  You can then use this environment to deploy to a cluster(s) 

**Q. How do I have multiple release of my app?**

**A.** When adding your app using wego, append an `@` + your version to the name of your app.  For example, myapp@v0.2.0. After these, you can define environments and apply to clusters like all other apps.

**Q. Do I have to have an environment to deploy my app to a cluster?**

**A.** No.  The kustomize file in the cluster can refer to you application directory directly. 

**Q. When creating a cluster usig MCCP where are my CAPI manifests stored?**

**A.** The are stored in a special application named `capi`.  They are named based on the cluster name you give. 

**Q. What are the extra characters on the directory name of my clusters?**

**A.** Clusters are considered ephemeral and Weave GitOps appends those characters to keep the cluster name unique.

**Q. When should I put manfiests in cluster/&lt;name&gt;/system vs cluster/&lt;name&gt;/user?**

**A.** Typically, you want system or OS level workloads defined in system/ and user workloads or applications stored in user/.  You can configure user/ and system/ to sync on different intervals.

**Q. What does the directory structure look like if I'm using team workspaces?**

**A.** TBD. One alternative is to create a workspaces directory containing the definition of the workspace plus a kustomization that pulls in workloads similar to how a cluster works.

**Q. How do I remove an application from a specific cluster**

**A.** Edit the kustomization.yaml file and remove the line pulling in the application.

**Q. My application manafests and kustomizations live in a application repo.  How do environments work in this case?**

**A.** When adding the app, the source resource will be stored in the apps/&lt;name&gt;/ directory.  For each kustomization in your application repo you will want to create an environment and kustomization file that informs Weave GitOps where to find the kustomzation overlay files.

**Q. When does this directory structure get created?**

**A.** TBD.  One alternative is a new command `wego gitops init` which creates the directory structure and optionally the intiial cluster.

**Q. Is `-hub` required for my management cluster?**

**A.** No.  The management cluster can be named anything you like.

**Q. With this being a single repository, how can I restrict who can make changes to apps, clusters, system workloads, etc?**

**A.** We recommend using the code owners facility from your git server. 

**Q. Can a cluster refer to more than one Weave GitOps repo?**

**A.** Not currently, however, we do plan to support this.  We can envison a platform team building clusters for use by other teams.  That platform team would have their own Weave GitOps repo, provision the cluster, then make the cluster available to the team to use.  In this initial release the platform team would be responsible for system workloads and we recommend using the Code Owners facility to manage access.

**Q. If one of my apps is comprised of a helm chart, where should my values.yaml file live?**

**A.** If the values change depending on the environment the chart is deployed into (dev vs stage) then the best practice is to put the values.yaml file in the environment directory.

**Q. Could my rendered cluster manifests live in another directory**

**A.** Yes.  One way would be for you to `wego app add` your other repository and Weave GitOps will setup the source and kustomization resources for you.

**Q. Is there any support for dependencies between applications and profiles?**

**A.** Not currently.  These are treated independently. Additionally, a profile can't depend on an application.

**Q. Could the profiles directory be considered a "profile catalog" for profiles available to this Weave GitOps environment?**

**A.** Seems like a reasonable idea.  **Kevin thoughts?**

**Q. Where are secrets stored in this layout**

**A.** We are striving to keep secrets outside the git repository and therefore this structure.  However, we don't enforce that the user isn't using solutions like SOPS or sealed secrets with their application manifests.

**Q. With the Weave GitOps repo containing configuration for numerous clusters, it seems like it could be easy to cause a lot of damage in a single commit**

**A.** This is true.  We recommend that you have a limited set of maintainers for the repository and don't allow direct commits to the branch storing the configurations.

**Q. My organization uses branches instead of directories for different environments/configs.  Is this possible with Weave GitOps**

**A.** Yes.  There are several alternatives for making this work.  A key piece of the configuration is to make sure the `*-flux-source-resource.yaml` files refer to the git ref (tag, commit) of the Weave GitOps repo. One alternative - 
* add all the apps on the main branch
* create a branch for each cluster
* add your cluster(s) that will have the same configruation to the branch
* customize and deploy your applications
* repeat for each environment/cluster
* when your applications need updating, modify the main branch and merge into the branch or cherrypick changes to the branch

**Q. Are env 1-1 for clusters?**

**A.** No.  The env directory is used to specialize an application for deployment.  For example, when deploying the MCCP in dev you will want to use SQLite; in staging and production, you would use Postgres.  You may have many dev clusters, and they could all point to env/dev.

**Q. What is the difference between apps and profiles?**

**A.** Apps are typically user workloads deployed to clusters and primarily referenced from the `user` directory.  Profiles generally are system-level workloads and primarily referenced from the `system` directory.  Another way to think about them is `system` is similar to `/usr/bin` while `user` is similar to `/usr/local/bin`.

**Q. I keep all my application manifests in a mono repo using tags for releases. How can I control what application version is deployed to what cluster?**

**A.** Each application in the wego directory within the wego repo will have a git source and kustimization where the git source will refer to your mono repo plus a repo ref (tag, branch).  Your clusters will have a git source and kustomization pointing to the wego repo plus a ref (tag, branch).  You can have clusters pulling the same version of apps by tieing them to the same ref.  

When your app is ready to have a new version deployed, you can update the app in the wego repo and either update the ref the cluster(s) points at or if your ref is a branch, cherry-pick your application changes to the branch.

By following this git-ref strategy, you can leverage git for operations like diffing changes between versions, cherry-picking changes, and easily controlling a group of applications and the set of clusters running them.
## Decision

Switch to the directory structure with 3 top level entries (apps, clusters, profiles) add support for versoins and environments.  

```bash
.weave-gitops/
├── apps
│   ├── billing@v2
│   │   └── env
│   │       ├── dev
│   │       └── dev-eu
│   └── capi
├── clusters
│   ├── dev-eu-fcabbe8
│   │   ├── system
│   │   └── user
│   └── management-hub
│       ├── system
│       └── user
└── profiles
    ├── loki
    └── platform.wego.weave.works
```
See below for a complete example.

## Alternatives considered

**TODO add links to the wego-dirs repo branches**

## Consequences

With the new structure, we will need to update existing installations: 
* rename `.wego` to `.weave-gitops`
* rename `targets` to `clusters`

**TODO finish the mapping**

## Compete example

```bash
.weave-gitops/
├── apps
│   ├── billing
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── env
│   │   │   ├── base
│   │   │   │   └── replica_count.yaml
│   │   │   ├── dev
│   │   │   │   └── kustomization.yaml
│   │   │   └── stage
│   │   │       ├── kustomization.yaml
│   │   │       └── replica_count.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   ├── billing@v2
│   │   ├── configmap.yaml
│   │   ├── deployment.yaml
│   │   ├── env
│   │   │   ├── dev
│   │   │   │   └── kustomization.yaml
│   │   │   └── dev-eu
│   │   │       └── kustomization.yaml
│   │   ├── kustomization.yaml
│   │   └── service.yaml
│   ├── capi
│   │   ├── app.yaml
│   │   ├── capa-template.yaml
│   │   ├── capd-template.yaml
│   │   ├── dev-eu.yaml
│   │   └── kustomization.yaml
│   └── mynginx-with-remote-manifests
│       ├── app.yaml
│       ├── flux-kustomization-resource.yaml
│       ├── flux-source-resource.yaml
│       └── kustomization.yaml
├── clusters
│   ├── dev-eu-fcabbe8
│   │   ├── system
│   │   │   ├── flux-source-resource.yaml
│   │   │   ├── kustomization.yaml
│   │   │   ├── system-flux-kustomization-resource.yaml
│   │   │   └── user-flux-kustomization-resource.yaml
│   │   ├── user
│   │   │   ├── kustomization.yaml
│   │   │   └── my-random-deployment.yaml
│   │   └── wego-cluster.yaml
│   └── management-hub
│       ├── system
│       │   ├── flux-source-resource.yaml
│       │   ├── kustomization.yaml
│       │   ├── system-flux-kustomization-resource.yaml
│       │   └── user-flux-kustomization-resource.yaml
│       ├── user
│       └── wego-cluster.yaml
└── profiles
    ├── capa.wego.weave.works
    │   ├── kustomization.yaml
    │   ├── profile.yaml
    │   └── template.yaml
    ├── capd.wego.weave.works
    │   ├── kustomization.yaml
    │   ├── profile.yaml
    │   └── template.yaml
    ├── loki
    │   ├── kustomization.yaml
    │   ├── loki-hr.yaml
    │   ├── loki-promtail-hr.yaml
    │   ├── namespace.yaml
    │   └── profile.yaml
    ├── platform.wego.weave.works
    │   ├── kustomization.yaml
    │   ├── platform.yaml
    │   └── profile.yaml
    ├── prometheus
    │   ├── kustomization.yaml
    │   └── profile.yaml
    └── prometheus@v2.24.0
        ├── kustomization.yaml
        └── profile.yaml
    ```

