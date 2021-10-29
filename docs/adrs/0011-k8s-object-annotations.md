# 11. K8s Object Annotations

Date: 2021-10-29

## Status

Accepted

## Context

Kubernetes [labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) and [annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) are both ways of adding metadata to Kubernetes objects.

 * Kubernetes labels allow you to identify, select and operate on Kubernetes objects.
 * Annotations are generally used to provide extra information for components to
   operate on.

We are adopting standard metadata for K8s objects to provide scope for building
improved user-experiences, specifically around rendering UIs and search.

## Decision

We should be applying Kubernetes' ["Recommended Labels"](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/) to objects where
appropriate.

We can add the labels through the Kustomize [commonLabels](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/#kustomize-feature-list) feature:

```shell
$ cat kustomization.yaml
commonLabels:
  app.kubernetes.io/managed-by: wego
  app.kubernetes.io/created-by: wego-api
  app.kubernetes.io/part-of: <insert app name>
```

This would result in objects being labelled as follows:

```yaml
metadata:
  labels:
    app.kubernetes.io/part-of: test-application
    app.kubernetes.io/managed-by: wego
    app.kubernetes.io/created-by: wego-api
```

## Clusters

Because we will have multiple clusters in the system, we should also be applying
standard annotations to those:

```yaml
  labels:
    capi.weave.works/managed-by: wego
    capi.weave.works/created-by: wego-capi
```

## Consequences

The Kubernetes recommended labels provide additional metadata that tooling
within the K8s ecosystem can be built ontop of, OpenShift for example, uses the
K8s recommended labels to build the operations UI.

There is no requirement for users to apply the labels, but there is a benefit to
maintaining them.
