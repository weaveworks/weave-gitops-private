# RFC-0001 Continuous Delivery Pipelines in Weave GitOps

<!--
The title must be short and descriptive.
-->

**Status:** implementable

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-07-29

**Last update:** 2022-08-09

## Summary

<!--
One paragraph explanation of the proposed feature or enhancement.
-->

Weave GitOps should provide users with the ability to define continuous delivery pipelines by creating a `Pipeline` Kubernetes custom resource. This resource will hold references to all environments and -- within those -- deployment targets than an application will be deployed through, e.g. "dev", "staging" and "production". Different roles within an organization will be able to (1) define a pipeline (this is usually done by an ops team) (2) add workloads to a given pipeline (this is usually done by one of possibly several application development teams). A pipeline consists of a sequential list of several environments and each environment consists of one or more deployment targets. Applications can be observed at each level of the pipeline while updates are progressing through the environments.

## Motivation

<!--
This section is for explicitly listing the motivation, goals, and non-goals of
this RFC. Describe why the change is important and the benefits to users.
-->

Users of Weave GitOps want the ability to set up a pipeline for delivering applications through a series of stages, e.g. from a dev stage to staging and then to production. That process can be hard to build and a lot of companies end up with custom code and complex mechanisms to ensure the workflow meets their needs. Continuous Delivery (CD) Pipelines will let users set up safe and secure pipelines. At its most simple, it will allow application operators to easily understand the state of their application updates across a set of environments. It should enable application teams to be able to own their own deployments and to release at their own pace.

### Terminology

- **CD Pipeline**: A CD Pipeline declares a series of environments through which a given application is expected to be deployed.
- **Environment**: An environment consists of one or more deployment targets. An example environment could be “Staging”.
- **Deployment target**: A deployment target is a Cluster and Namespace combination. For example, the above “Staging” environment, could contain {[QA-1, test], [QA-2, test]}.
- **Application**: A Helm Release or an Image. 
- **Progressive Delivery / Rollout**: Updates to an application flow from one environment to the next. This has no relationship to Flagger

### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->

* Define an API for declaring a pipeline using mostly out-of-the-box Kubernetes machinery (e.g. built-in types) and, if necessary CustomResourceDefinitions.
* Prescribe as little as possible in terms of what a pipeline is comprised of or what its targets are. A pipeline may consist just of a single environment, multiple environments and each environment may consist of as many targets as necessary from a user's perspective.
* Users should be able to apply well-known access control mechanisms to pipelines so that e.g. only a certain group of people can create pipelines or add workloads to an existing one.
* The approach should be complementary to and agnostic of CI implementations. A pipeline should be able to "pick up" from any Continuous Integration (CI) pipeline.
* Leave enough room for further elaboration of the design to add features such as automatic workload promotion through the stages of a pipeline.

### Non-Goals

<!--
What is out of scope for this RFC? Listing non-goals helps to focus discussion
and make progress.
-->

* Automatic promotion of applications through the stages of a pipeline is not part of this proposal but the proposal should allow for building that on top.

## Proposal

<!--
This is where we get down to the specifics of what the proposal actually is.
This should have enough detail that reviewers can understand exactly what
you're proposing, but should not include things like API designs or
implementation.

If the RFC goal is to document best practices,
then this section can be replaced with the the actual documentation.
-->

A new custom resource definition lets users define a pipeline and the associated environments in a central place. Each pipeline is represented by a single resource consisting of a list of all the environments in turn consisting of a list of the environment's targets. The order of environments is mandated by each environment's position in that list.

A workload is made part of such a pipeline environment by applying the label `pipelines.wego.weave.works/pipeline` to one or more Flux [Kustomizations](https://fluxcd.io/docs/components/kustomize/kustomization/) or [HelmReleases](https://fluxcd.io/docs/components/helm/helmreleases/). Each of these labelled resources within the same pipeline (i.e. with the same label value) represents one or more applications deployed to one target of that pipeline.

All pipeline workloads can reside in a different Namespace on the same cluster or across different clusters as a pipeline is usually considered to span at least different Namespaces and usually several clusters. The focus of this proposal, though, is each workload being deployed on multiple clusters as that is assumed to be the prevailing scenario for end users.

### User Stories

<!--
Optional if existing discussions and/or issues are linked in the motivation section.
-->

#### Story 1

> As a user, I am able to define an object for a Pipeline, which declares a series of namespaces residing on different clusters through which an application update should be applied in sequence.

In this example we're going to create a pipeline called "podinfo" with the two environment targets "dev" and "prod", each represented by the "podinfo" Namespace on different clusters each. A single application "podinfo" is deployed as part of that pipeline, with version 6.1.6 going to the "dev" environment and 6.1.0 going to the "prod" environment:

1. Create the pipeline definition

   ```sh
   $ cat << EOF | kubectl apply -f-
   apiVersion: pipelines.wego.weave.works/v1alpha1
   kind: Pipeline
   metadata:
     name: podinfo
     namespace: default
   spec:
     environments:
       - name: dev
         targets:
           - namespace: podinfo
             clusterRef:
               kind: GitopsCluster
               name: dev
       - name: prod
         targets:
           - namespace: podinfo
             clusterRef:
               kind: GitopsCluster
               name: prod
   ```

1. Create Namespaces and sources on both clusters

   ```sh
   $ for c in dev prod ; do \
       kubectl --context="$c" create ns podinfo ; \
       flux --context="$c" -n podinfo create source helm podinfo --url=oci://ghcr.io/stefanprodan/charts ; \
     done
   ```

1. Create the "dev" environment HelmRelease, deploying chart version 6.1.6

   ```sh
   $ flux --context=dev -n podinfo create hr podinfo --target-namespace=podinfo --source=HelmRepository/podinfo --chart=podinfo --chart-version=6.1.6 --label=pipelines.weave.works/pipeline=podinfo
   ```

1. Create the "prod" environment HelmRelease, deploying chart version 6.1.5

   ```sh
   $ flux --context=prod -n podinfo create hr podinfo --target-namespace=pdoinfo --source=HelmRepository/podinfo --chart=podinfo --chart-version=6.1.5 --label=pipelines.weave.works/pipeline=podinfo
   ```

#### Story 2

> As a user, I am able to view the state of my application across its defined environments. Including its status and an appropriate version definition which should include all image tags.

The state of a pipeline and its workloads is reflected in the pipeline resource's status:

```sh
kubectl describe pipeline podinfo
[...]
Status:
  Environments:
    Dev:
      Targets:
        Kind: GitopsCluster
        Name: dev-us
        Workloads:
          Kind:    Deployment
          Name:    podinfo-pipeline
          Version: 6.1.8
          Kind:    Deployment
          Name:    podinfo-pipeline-2
          Version: 6.1.8
        Kind: GitopsCluster
        Name: dev-eu
        Workloads:
          Kind:    HelmRelease
          Name:    podinfo-pipeline-helm
          Version: 6.1.8
```

#### Story 3

> As an Enterprise user, I am able to create a new pipeline from within the UI and commit this to git.

Creation of a new pipeline is a matter of creating a `Pipeline` custom resource within the desired Namespace. Providing this functionality through the UI can easily be done with a form.

#### Story 4

> As a user I can define a Pipeline which declares a series of Environments made up of one or more Deployment Targets.

This story is very similar to story 1 with the only difference being that we now define multiple targets for the "dev" environments. Taking the example from story 1, we will create a pipeline "podinfo" where the dev environment now consists of two targets "dev-us" and "dev-eu":

```sh
$ cat << EOF | kubectl apply -f-
apiVersion: pipelines.wego.weave.works/v1alpha1
kind: Pipeline
metadata:
  name: podinfo
  namespace: default
spec:
  environments:
    - name: dev
      targets:
        - namespace: podinfo
          clusterRef:
            kind: GitopsCluster
            name: dev-us
        - namespace: podinfo
          clusterRef:
            kind: GitopsCluster
            name: dev-eu
    - name: prod
      targets:
        - namespace: podinfo
          clusterRef:
            kind: GitopsCluster
            name: prod
```

#### Story 5

> As a user, I can configure a Pipeline to progressively update my application across environments, based on image tag or helm chart version, through GitOps.

This is out of scope of this particular proposal but can be achieved by patching an application manifest representing a certain stage of a pipeline. Some conventions may facilitate this step, e.g. mandating that an application manifest has the same name and is deployed in the same namespace across the clusters comprising the stages of a pipeline.

#### Story 6

> As a user, I am able to configure progressive rollouts to be automatic or controlled via Pull Request

This is out of scope of this proposal but is similar to story 5.

#### Story 7

> As a user, I can trigger a pipeline execution from my existing CI based on a webhook.

By convention, a pipeline execution would be triggered by a change of the application deployed to the first environment in the list of environments of the `Pipeline` resource the application is part of. Flux's image update automation may facilitate automating this step.

#### Story 8

> As a user, when a rollout fails due to environmental issues, once those are resolved, the pipeline should automatically resume.

This is out of scope of this proposal but is similar to story 5.

#### Story 9

> As a user, I can discover the status of my update, which environment(s) has it been applied to successfully/unsuccessfully, at what stage is it currently?

This proposal supports this use case. An example configuration would work in such a way that deployments to the first environment of a pipeline (usually called "dev") are performed automatically, e.g. by using Flux's built-in image automation or Helm chart discovery (using a semver range in `.spec.chart.spec.version`). After an automatic rollout to this first environment, users would be able to see that a new version has been deployed to that environment. Any further progression to subsequent environments may be performed using automation built on top of this initial rollout or by manually updating the respective manifests in the Git repository.

The design put forward in this proposal does not rely on the notion of an "update" that progresses through environments, though, but rather allows for introspecting certain states each application is in within each environment of a pipeline.

#### Story 10

> As an administrative user, I am able to control who can pause and resume a pipeline through appropriate configuration.

This proposal does not prescribe the means of how updates are pushed through the environments of a pipeline and consequentially depends on downstream automation to handle this case. The simplest case would be that no further automation is put in place, meaning that updates are performed by someone pushing to Git (maybe using a PR/MR process). Pausing in this scenario would mean that version updates aren't pushed to Git. This would have to be enforced by processes, e.g. by holding a PR.

#### Story 11

> As a user, I can query an API for all helm chart versions deployed across my connected clusters

See story 2.

#### Story 12

> As a user, I can query an API for all image tags for deployments across my connected clusters

This proposal doesn't block this requirement but the story might need to be elaborated on to ensure the meaning of it is clearly understood.

#### Story 13

> As a user, I can follow a guide to set up CI/CD with Tekton and Weave GitOps, including testing, linting, security scanning, building and publishing activities alongside a GitOps deployment. 

This proposal is not preventing this story as the required steps can be documented and possibly augmented by tooling around the Pipeline CRD.

#### Story 14

> As a user I can discover the related Flux objects for an application on a given cluster from the Pipelines view.

This should be doable similar to what `flux tree ks` does for Kustomizations. For Helm Releases this might be a little more complicated but is not specific to pipelines but to HelmRelease introspection in general.

#### Story 15

> As a user, I can discover what triggers exist for a given pipeline

Triggering a pipeline (i.e. a deployment to the first environment) is out of scope of this proposal but the proposal does not impose any specific mechanisms to trigger deployments.

#### Story 16

> As a user, I can see the artifact that is being promoted across my declared environments and its version.

See story 2.

### Alternatives

<!--
List plausible alternatives to the proposal and explain why the proposal is superior.

This is a good place to incorporate suggestions made during discussion of the RFC.
-->

The following alternatives have been considered:

#### Pure Label-based Pipelines

This approach would rely on each workload defining the environment it's to be considered part of by means of applying one more labels in addition to the `pipelines.weave.works/pipeline` label. That label would be called `pipelines.weave.works/environment`. This approach has been considered to come with too many drawbacks especially around the following aspects:

* Access control
  * Pipeline creation: With a pipeline defined purely by the existence of a deterministic label on a workload resource (e.g. a Kustomization or a HelmRelease), it is hard to define an environment in which only a certain group of people are allowed to define pipelines (e.g. an operations team). A possible way to do so would be to bring in a policy management solution such as Kyverno or OPA Gatekeeper but that requires additional tooling to be installed on each cluster where pipelines could possibly be created as well as maintaining the specialized policy rules.

    With a CRD-based approach such as the one proposed in this document, it is very simple to define a group of people that can create pipelines by using built-in Kubernetes RBAC machinery such as RoleBindings specific to kinds of that CRD.
  * Workload management: how do I prevent workloads being added to a pipeline by a rogue actor? Anyone who can create workloads in a certain Namespace on a cluster would be able to add their own workload to a pipeline. This is very simple from the individual engineer's perspective but hard to build a policy around where only certain workloads are allowed to be added to a pipeline. Without additional tooling enforcing such a policy this is not possible.

    With the CRD-based approach adding a workload to an environment of a pipeline is constrained to a single Namespace on a single cluster.
* Performance/scalability: In order to build a list of all pipelines that exist across the management cluster and all leaf clusters one would have to query all Namespaces on all clusters for workloads and parse their labels. Given there's N clusters and M workload kinds to look for, that's N\*M API calls. In the best case the number of API calls can be kept as low as possible by restricting the number of workload kinds, e.g. to only Kustomizations and HelmReleases which would result in N\*2 API calls, making the query scale linearly with the number of clusters.

  In the CRD-based approach building up a list of all pipelines would be much simpler in that one would only have to fetch all Pipeline resources. Depending on the specific environment this can be further restricted to a single API call when Pipelines can only be created on the management cluster. When pipelines can be created on leaf clusters as well, the number of API calls is linear to the number of clusters. See the [Scalability](#scalability) section for further elaboration on this topic.

#### Full CRD-based Pipelines

This approach is similar to the one proposed in this document but would extend the CRD to hold references to each workload deployed as part of the pipeline:

```yaml
apiVersion: wego.weave.works/v1alpha2
kind: Pipeline
metadata:
  name: example-pipeline
  namespace: flux-system
spec:
  stages:
    - name: dev
      namespace: dev
      order: 1
      releaseRefs: # list of `Kustomization` or `HelmRelease` objects. They MUST be in the defined stage namespace
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: dev # name of kustomization object (doesn't have to match stage name)
          kind: Kustomization
    - name: staging
      namespace: staging
      order: 2
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: staging
          kind: Kustomization
    - name: prod
      namespace: prod
      order: 3
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: prod
          kind: Kustomization
```

While it has the benefit of being very easy to reason about in terms of the state of a pipeline it was considered to be too centralized for it to be practical, considering that a pipeline is maintained by a different team than the workloads deployed through it. The pipeline resource would also become very big when e.g. an environment would be comprised of many workloads.

#### ConfigMap-based Pipelines

This approach mostly matches with the approach proposed in this document with the difference that pipelines would be defined in a ConfigMap instead of a CRD. While it bears the benefit of not having to create the CRD resource, the drawbacks have been considered to outweigh this benefit:

- It is hard for users to understand the structure of the data within such a ConfigMap as there is no schema available for it. Mistakes will be made a lot and it's hard to debug them.
- Installing a CRD is a very lightweight and simple task and can be done as part of installing Weave GitOps itself.

## Design Details

<!--
This section should contain enough information that the specifics of your
change are understandable. This may include API specs and code snippets.

The design details should address at least the following questions:
- How can this feature be enabled / disabled?
- Does enabling the feature change any default behavior?
- Can the feature be disabled once it has been enabled?
- How can an operator determine if the feature is in use?
- Are there any drawbacks when enabling this feature?
-->

Weave GitOps releases will include the Pipeline CRD to be installed on a management cluster together with Weave GitOps itself. An accompanying controller watching Pipeline resources will keep their `.status` field up-to-date for simple inspection.

The Weave GitOps UI will present the user with a way to list all pipelines as well as a way to inspect each one of them.

### `Pipelines` CRD

All fields of the CRD's `spec` field shown in the sections above are mandatory except for `spec.environments.targets.clusterRef`. If the `clusterRef` is not set, the target is assumed to live on the same cluster as the pipeline resource itself.

### Access Control, Security & Validation

* **How do I constrain pipeline declaration to a group of people?** Using built-in RBAC mechanics it is a matter of defining proper RoleBindings to only let certain subjects create/update/delete a pipeline.
* **How do I prevent workloads being added to a pipeline by a rogue actor?** A pipeline's target is always constrained to a single Namespace so only people being able to create and label workloads in that specific Namespace can add a workload to a pipeline. It is a matter of constraining access to that specific Namespace to prevent hijacking a certain pipeline.
* **what happens if I create a Pipeline refering to a non-existing Namespace or cluster?** The Pipeline's `.status` field should reflect any issues deriving the workloads it is referring to. Failure to fetch the workloads of one target should not affect the status of any other targets of that same or any other Pipeline.
* **what happens if I refer to a non-existing Pipeline from my HelmRelease?** Since pipelines are drilled into from top to bottom (i.e. from Pipeline CR to workloads) the HelmRelease would not turn up in any visualization of any pipeline's workloads.

### Scalability

#### Showing all Pipelines

Building up a list of all pipelines is a matter of fetching all Pipeline resources from all clusters. Depending on the specific environment this can be further restricted to a single API call when Pipelines can only be created on the management cluster. When pipelines can be created on leaf clusters as well, the number of API calls is linear to the number of clusters.

#### Showing all Stages of a Single Pipeline

Building up a list of all environments and their workloads within a single pipeline is a multi-step process and involves cross-cluster API querying. For each target in an environment represented by a Namespace on a certain cluster one API call has to be made per supported workload kind (e.g. Kustomization and HelmRelease). In a pipeline that has E environments, each consisting of T targets (a target being a Namespace on a particular cluster) and a number of W supported workload kinds that would result in E\*T\*W API calls. Given that W is constant the number of API calls is proportional to E\*T and grows linearly with the number of environments.

### Risks

#### Tracking Resources Back To Their Source

In this proposal, in order to automatically promote a certain application from one stage to another, a tool would have to find the manifest definition in its Git repository only by introspecting Kubernetes API objects. This is non-trivial and needs to be investigated further.

## Implementation History

<!--
Major milestones in the lifecycle of the RFC such as:
- The first Flux release where an initial version of the RFC was available.
- The version of Flux where the RFC graduated to general availability.
- The version of Flux where the RFC was retired or superseded.
-->

