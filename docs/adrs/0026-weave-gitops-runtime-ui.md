# 26. Extend Flux Runtime UI to Weave GitOps Runtime UI 

Date: 2023-12-04

## Status

Accepted

## Context

Requested from CX to extend Flux Runtime UI for Weave GitOps Enterprise to include also controllers ecosystem under 

https://github.com/weaveworks/weave-gitops-interlock/issues/265

The following alternatives are possible:

a) extending the current solution so it works for both OSS and EE
b) replacing the current solution using Explorer-based UI that works in OSS and EE
c) creating a new UI in EE that leverages Explorer. The old UI remains

### Option A: Extending the current solution, so it works for both OSS and EE controllers.

Current solutions is available in OSS in [Flux Runtime](https://github.com/weaveworks/weave-gitops/blob/8779391d2ff2ecba59309b0d7b3fac5714da89e4/core/server/fluxruntime.go#L56). 
Where we are listing deployment by label:  

```
		opts := client.MatchingLabels{
			coretypes.PartOfLabel: FluxNamespacePartOf,
		}

		list := &appsv1.DeploymentList{}

		for _, fluxNs := range fluxNamepsaces {
			if err := clustersClient.List(ctx, clusterName, list, opts, client.InNamespace(fluxNs.Name)); err != nil {
				respErrors = append(respErrors, &pb.ListError{ClusterName: clusterName, Namespace: fluxNs.Name, Message: fmt.Sprintf("%s, %s", ErrListingDeployments.Error(), err)})
				continue
			}
```

A solution that would work for EE controllers would involve:

1. Refactor this experience to make it generic so we could include 
2. Use configuration to define the deployments to show in the UI:
   - OSS: to show Flux, Weave GitOps app, Tf-controller, Policy Agent, etc ...  
   - EE: the previous + EE controllers like pipeline, gitopssets, cluster-xxx 
3. Create UI via either option:
   1. To Rename Flux Runtime to Weave GitOps Runtime or 
   2. to Create another UI for Weave GitOps Runtime

#### Evaluation

(+) available to OSS and EE out of the box
(+) easily customizable to provide WGA runtime
(-) costs of maintenance and extension
(-) needs extension of existing API and UI


### Option B: Creating a new UI in EE that leverages Explorer. The old UI remains.

This solution would include:

1. Do not touch Flux Runtime 
2. Create Weave GitOps Runtime based on Explorer by 
   - extend Explorer to watch deployment 
   - define controller runtime kind to watch via label 
   - create generic UI to show the runtime controllers.

#### Evaluation

(+) costs of maintenance and extension
(-) not available in OSS
(-) needs extension of Explorer

### Option C: Replacing the current solution using Explorer-based UI that works in OSS and EE

This would include the previous solution but also requires:

1. OSS Explorer so it could be used in Weave GitOps OSS.  

#### Evaluation

(+) available in OSS
(+) costs of maintenance and extension
(-) needs OSS explorer 

## Decision

Given the previous alternatives, we are going to prioritise Option A due to its applicability to OSS and EE and 
because any of the alternatives requires extending Explorer or OSS Explorer which also involves additional effort.

### Proof of Concept on selected options

**Scenario A: OSS has Weave GitOps runtime**

In https://github.com/weaveworks/weave-gitops/pull/4162 where

1. Extended API runtime to also match deployments by label `app.kubernetes.io/part-of: weave-gitops`
2. Weave GitOps Controllers should be labelled with that weave-gitops label. For example, tf-controller should be labelled as follows:

```yaml 
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: tf-controller
  namespace: flux-system
spec:
  ...
  postRenderers:
    - kustomize:
        patchesStrategicMerge:
          - kind: Deployment
            apiVersion: apps/v1
            metadata:
              name: tf-controller
              labels:
                app.kubernetes.io/part-of: weave-gitops
          - kind: CustomResourceDefinition
            apiVersion: apiextensions.k8s.io/v1
            metadata:
               name: terraforms.infra.contrib.fluxcd.io
               labels:
                  app.kubernetes.io/part-of: weave-gitops
```
An example of OSS runtime with controllers beyond Flux could be:

![gitops-runtime-oss.png](images%2Fgitops-runtime-oss.png)

**Scenario A: EE has Weave GitOps runtime**

Given EE uses runtime API endpoints directly, importing an OSS branch would
make the logic available to WGE.

The following branch has the spike changes https://github.com/weaveworks/weave-gitops-enterprise/tree/wge-3600-gitops-runtime

![gitops-runtime-ee.png](images%2Fgitops-runtime-ee.png)

To solution:

- Finalise spike
- Ensure runtime controllers are decorated during release process with `app.kubernetes.io/part-of: weave-gitops`
- Rename Flux Runtime to Weave GitOps Runtime or just Runtime

## Consequences

- Users have a way to track runtime components beyond flux.   
- We have a simple way to extend it with limited costs (over other alternatives).  

