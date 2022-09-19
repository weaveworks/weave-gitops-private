# RFC-0002 Distributing Pipelines Controller as OCI Artifact

<!--
The title must be short and descriptive.
-->

**Status:** withdrawn

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-09-02

**Last update:** 2022-09-16

## Summary

<!--
One paragraph explanation of the proposed feature or enhancement.
-->

Pipeline-controller should be distributed as an OCI artifact and consumed using Flux's `OCIRepository` and `Kustomization` APIs as part of Weave GitOps Enterprise installation.

## Motivation

<!--
This section is for explicitly listing the motivation, goals, and non-goals of
this RFC. Describe why the change is important and the benefits to users.
-->

The [Pipeline Controller](https://github.com/weaveworks/pipeline-controller) is a controller and CRD adding functionality around Continuous Delivery Pipelines to Weave GitOps Enterprise (and eventually Weave GitOps OSS). It is supposed to be distributed alongside Weave GitOps Enterprise (WGE) when users install WGE.

### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->

* Transparently install pipeline-controller during installation of the [WGE Helm chart](https://github.com/weaveworks/weave-gitops-enterprise/tree/4174e4ec39743bd66c0c3ffc35e1cfff4d67cd16/charts/mccp).

### Non-Goals

<!--
What is out of scope for this RFC? Listing non-goals helps to focus discussion
and make progress.
-->

## Proposal

<!--
This is where we get down to the specifics of what the proposal actually is.
This should have enough detail that reviewers can understand exactly what
you're proposing, but should not include things like API designs or
implementation.

If the RFC goal is to document best practices,
then this section can be replaced with the the actual documentation.
-->

Pipeline-controller is distributed in the form of an OCI manifest hosted at the ghcr.io registry. It is then installed by creating an [`OCIRepository`](https://fluxcd.io/flux/components/source/ocirepositories/) and a [`Kustomization`](https://fluxcd.io/flux/components/kustomize/) consuming that repository. These two manifests are included in the Weave GitOps Enterprise "mccp" Helm chart. Please see [the Flux documentation](https://fluxcd.io/flux/cheatsheets/oci-artifacts/#consuming-artifacts) for details.

### Release Process

In addition to building and tagging the container image the OCI artifact will be created using the Flux CLI:

```sh
	flux push artifact oci://ghcr.io/weaveworks/manifests/pipeline-controller:$(IMG_TAG) --path=./config/ --source=https://github.com/weaveworks/pipeline-controller --revision=$(IMG_TAG)/$(shell git rev-parse HEAD)
```

### Upgrades and CRD Management

Upgrading the version of pipeline-controller used in WGE is accomplished by changing the `.spec.ref.tag` field of the `OCIRepository` manifest and releasing a new version of the "mccp" chart to which a running release would be upgraded.

Any potentially changed CRDs that are part of pipeline-controller are automatically upgraded as well.

### Benefits

1. **Simple release process**: Distributing pipeline-controller as an OCI artifact leads to a much slimmer release process (see above) compared to alternatives such as using Helm charts where a Helm repository would have to be maintained.
1.  **More reliable artifacts**: We do already use kustomize in the pipeline-controller repository to deploy it locally during development (that's a kubebuilder default). As an effect the tooling and manifests are very well tested because every engineer makes use of them during daily development. Any separate way of distributing pipeline-controller would have to be augmented with similar testing and tooling which comes with more overhead.

### Implications

Using OCIRepository requires Flux 0.32+. There is no strict policy in place at the moment as to which Flux version WGE supports. In order to not break WGE installation for users running older version of Flux on their clusters, the two manifests above could make use of Helm's `Capabilities.APIVersion` object in the "mccp" chart:

```
{{- if .Capabilities.APIVersions.Has "source.toolkit.fluxcd.io/v1beta2/OCIRepository" -}}
...
{{- end }}
```

This would lead to pipeline-controller not being installed on those clusters until the operator upgrades Flux on the cluster and the "mccp" HelmRelease is reconciled.

An alternative approach would be to make Flux 0.32+ mandatory starting with the WGE version shipping pipeline-controller which would be in line with the policy of recommending upgrading Flux regularly, too.

### Alternatives

<!--
List plausible alternatives to the proposal and explain why the proposal is superior.

This is a good place to incorporate suggestions made during discussion of the RFC.
-->

The only alternative considered was to publish a Helm chart for pipeline-controller and making it a dependency of the "mccp" WGE chart. However, this has an obvious drawback which is that most of the manifests from the kustomize tooling used during development would have to be duplicated and kept in sync with the chart manifests. Accommodating this would be done by completely removing the kustomize tooling from the repository and only using Helm charts during development. However, adding the overhead of Helm templating and chart versioning/publication isn't deemed to provide a benefit over the more lightweight kustomize approach.

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

Two files are added to the WGE "mccp" chart's templates:

```yaml
# ocirepository_pipeline-controller.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: pipeline-controller
  namespace: flux-system
spec:
  interval: 10m0s
  provider: generic
  ref:
    tag: v0.0.1
  url: oci://ghcr.io/weaveworks/manifests/pipeline-controller
```

```yaml
# kustomization_pipeline-controller.yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: pipeline-controller
  namespace: flux-system
spec:
  interval: 1h0m0s
  path: ./config/default
  prune: true
  sourceRef:
    kind: OCIRepository
    name: pipeline-controller
  targetNamespace: flux-system
  timeout: 2m0s
  wait: true
```

## Implementation History

<!--
Major milestones in the lifecycle of the RFC such as:
- The first Flux release where an initial version of the RFC was available.
- The version of Flux where the RFC graduated to general availability.
- The version of Flux where the RFC was retired or superseded.
-->
