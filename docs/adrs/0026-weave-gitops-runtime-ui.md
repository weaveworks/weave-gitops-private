# 26. Explorer Collector Deletion Detection

Date: 2023-12-04

## Status

Proposed

## Context

Requested from CX to extend flux runtime UI for weave gitops enterprise to include also controllers ecosystem under 

https://github.com/weaveworks/weave-gitops-interlock/issues/265

The following alternatives are possible:

a) extending the current solution so it works for both OSS and EE
b) replacing the current solution using explorer-based UI that works in OSS and EE
c) creating a new UI in EE that leverages explorer. the old UI remains

### Option A: Extending the current solution, so it works for both OSS and EE controllers.

Current solutions is available in OSS in [flux runtime](https://github.com/weaveworks/weave-gitops/blob/8779391d2ff2ecba59309b0d7b3fac5714da89e4/core/server/fluxruntime.go#L56). 
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
   - oss: to show Flux, Weave Gitops app, Tf-controller, Policy Agent, etc ...  
   - ee: the previous + ee controllers like pipeline, gitopssets, cluster-xxx 
3. Create UI via either option:
   1. To Rename Flux Runtime to Weave Gitops Runtime or 
   2. to Create another UI for Weave Gitops Runtime

#### Evaluation

(+) available to OSS and EE out of the box
(+) easily customizable to provide WGA runtime
(-) costs of maintenance and extension
(-) needs extension of existing api and UI

### Option B: Creating a new UI in EE that leverages explorer. The old UI remains.

This solution would include:

1. Do not touch Flux Runtime 
2. Create Weave Gitops Runtime based on explorer by 
   - extend explorer to watch deployment 
   - define controller runtime kind to watch via label 
   - create generic UI to show the runtime controllers.

#### Evaluation

(+) costs of maintenance and extension
(-) not available in OSS
(-) needs extension of explorer

### Option C: Replacing the current solution using explorer-based UI that works in OSS and EE

This would include the previous solution but also requires:

1. OSS Explorer so it could be used in Weave Gitops OSS.  

#### Evaluation

(+) available in OSS
(+) costs of maintenance and extension
(-) needs OSS explorer 

## Decision

Given the previous alternatives, we are going to prioritise Option A due to its applicability to OSS and EE and 
because any of the alternatives requires extending Explorer or OSS Explorer which also involves additional effort. 

## Consequences

TBA

