# RFC-000N Markers in YAML Comments for Application Promotion

<!--
The title must be short and descriptive.
-->

**Status:** implemented

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-11-10

**Last update:** 2022-11-10

## Summary

<!--
One paragraph explanation of the proposed feature or enhancement.
-->

Provide a mechanism by which Pipelines can target the correct manifest to effect a promotion, and make the appropriate change, when using the pull-request strategy.

## Motivation

<!--
This section is for explicitly listing the motivation, goals, and non-goals of
this RFC. Describe why the change is important and the benefits to users.
-->

[RFC 0003](../0003-pipelines-promotion) describes the general promotion flow and defines the possibility for several distinct promotion strategies to be implemented. One of these promotion strategies further described in [this document of the same RFC](0003-pipelines-promotion/execute-promotion.md#create-a-pr) is one that creates a PR for promoting an app version to the next environment. For this to work the implementation will need to determine which field in which YAML manifest file in the repository contains the app version. One such approach is described herein.

### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->

- Define a means for discovering a specific field in one or more YAML files located in a particular directory hierarchy.
- Define a way to update that field in-place in all of the relevant files.

## Proposal

<!--
This is where we get down to the specifics of what the proposal actually is.
This should have enough detail that reviewers can understand exactly what
you're proposing, but should not include things like API designs or
implementation.

If the RFC goal is to document best practices,
then this section can be replaced with the the actual documentation.
-->

Similar to what Flux offers with [image update automations](https://fluxcd.io/flux/guides/image-update/#configure-image-update-for-custom-resources) this RFC proposes to use well-formatted YAML comments for discovering and updating fields pertaining to a certain Pipeline's application. Here is an example of such a comment:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
spec:
  postBuild:
    substitute:
      podinfoVersion: 6.2.0 # {"$promotion": "default:podinfo:prod"}
[...]
```

This comment is a JSON object comprised of the following parts:

- The key `$promotion` designates it as pertaining to pipeline promotions.
- The value `default:podinfo:prod` refers to the environment called "prod" in the Pipeline resource named "podinfo" in the Kubernetes Namespace "default".

An implementation of this RFC has the following inputs and outputs:

### Inputs

- A Pipeline that a particular promotion is supposed to represent
- An environment name. This can either be the target environment name ("prod" in the example above) or an environment preceeding the target environment (e.g. "dev"). In the latter case the implementation would have to fetch the Pipeline from the Kubernetes API and determine the target environment by itself.
- A field value that is used to update the field targeted by the given promotion. This can be a Helm chart version, a Git commit SHA, an image tag or any other value that makes sense in the given user scenario.

### Outputs

Given the inputs above an implementation is able to precisely determine which marker comment it is supposed to discover and with which value it shall update the targeted YAML field. The output of this operation is one or more modified YAML files.

### Alternatives

<!--
List plausible alternatives to the proposal and explain why the proposal is superior.

This is a good place to incorporate suggestions made during discussion of the RFC.
-->

This RFC is a retroactive definition of what has been implemented in pipeline-controller. No alternatives were considered for this initial delivery, but are recorded here for potential future iteration. The initial proposed approach was deemed viable primarily given its similar use within Flux. Coupled with the desire within Weave GitOps to both build natively on top of Flux, and to optimise for velocity and iteration based on customer feedback.

## Implementation History

<!--
Major milestones in the lifecycle of the RFC such as:
- The first Flux release where an initial version of the RFC was available.
- The version of Flux where the RFC graduated to general availability.
- The version of Flux where the RFC was retired or superseded.
-->

- Implemented in [pipeline-controller 0.0.4](https://github.com/weaveworks/pipeline-controller/releases/tag/v0.0.4)