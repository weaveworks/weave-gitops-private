# RFC-NNNN Title

<!--
The title must be short and descriptive.
-->

**Status:** provisional

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** YYYY-MM-DD

**Last update:** YYYY-MM-DD

## Summary

<!--
One paragraph explanation of the proposed feature or enhancement.
-->

## Motivation

<!--
This section is for explicitly listing the motivation, goals, and non-goals of
this RFC. Describe why the change is important and the benefits to users.
-->

At the back of the issue https://github.com/weaveworks/weave-gitops-interlock/issues/438 
it came to discuss how we manage RBAC errors in the API and how they are breaching tenancy isolation 
by extracting data among tenants. 

This RFC tries to provides 
- the context of the issue
- set of alternatives to avoid the issue
- analysis between alternatives 
- recommendation to follow from the alternatives

We will be using that endpoints as example to drive the design using three scenarios 

a) no multi-tenancy: either no multi-tenancy or just a single tenant. an example of this scenario is 
when its just a single team or set of teams in a single product with high-trust boundaries.
Example of environment: https://gitops.internal-dev.wego-gke.weave.works

b) soft-multi tenancy: multiple-tenant but they know or it is okay to know about each other. an example is a single 
organisation with different teams where its okay to have visibility on each other teams resources for read (not write).

c) hard-multi tenancy: examples of this could be 
 c.1: an enterprise with multiple teams or organisations that would like to have full tenant isolation 
 c.2: different organisations or enterprises: t
Example of environment: https://wge.trial.cx.weave.works/templates/tenant/create

The example of code to use is below

Where we could see there is  https://github.com/weaveworks/weave-gitops/blob/main/core/server/fluxruntime.go#L56C32-L56C32

And we should understand what is the layer that understands tenancy

```go
func (cs *coreServer) ListFluxRuntimeObjects(ctx context.Context, msg *pb.ListFluxRuntimeObjectsRequest) (*pb.ListFluxRuntimeObjectsResponse, error) {
respErrors := []*pb.ListError{}

	clustersClient, err := cs.clustersManager.GetImpersonatedClient(ctx, auth.Principal(ctx))
	if err != nil {
		if merr, ok := err.(*multierror.Error); ok {
			for _, err := range merr.Errors {
				if cerr, ok := err.(*clustersmngr.ClientError); ok {
					respErrors = append(respErrors, &pb.ListError{ClusterName: cerr.ClusterName, Message: cerr.Error()})
				}
			}
		}
	}

	var results []*pb.Deployment

	for clusterName, nss := range cs.clustersManager.GetClustersNamespaces() {
		fluxNamepsaces := filterFluxNamespace(nss)
		if len(fluxNamepsaces) == 0 {
			respErrors = append(respErrors, &pb.ListError{ClusterName: clusterName, Namespace: "", Message: ErrFluxNamespaceNotFound.Error()})
			continue
		}

		opts := client.MatchingLabels{
			coretypes.PartOfLabel: FluxNamespacePartOf,
		}

		list := &appsv1.DeploymentList{}

		for _, fluxNs := range fluxNamepsaces {
			if err := clustersClient.List(ctx, clusterName, list, opts, client.InNamespace(fluxNs.Name)); err != nil {
				respErrors = append(respErrors, &pb.ListError{ClusterName: clusterName, Namespace: fluxNs.Name, Message: fmt.Sprintf("%s, %s", ErrListingDeployments.Error(), err)})
				continue
			}

			for _, d := range list.Items {
				r := &pb.Deployment{
					Name:        d.Name,
					Namespace:   d.Namespace,
					Conditions:  []*pb.Condition{},
					ClusterName: clusterName,
					Uid:         string(d.GetUID()),
					Labels:      d.Labels,
				}

				for _, cond := range d.Status.Conditions {
					r.Conditions = append(r.Conditions, &pb.Condition{
						Message: cond.Message,
						Reason:  cond.Reason,
						Status:  string(cond.Status),
						Type:    string(cond.Type),
					})
				}

				for _, img := range d.Spec.Template.Spec.Containers {
					r.Images = append(r.Images, img.Image)
				}

				results = append(results, r)
			}
		}
	}

	return &pb.ListFluxRuntimeObjectsResponse{Deployments: results, Errors: respErrors}, nil
}
```


### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->

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
then this section can be replaced with the actual documentation.
-->

### User Stories

<!--
Optional if existing discussions and/or issues are linked in the motivation section.
-->

### Alternatives

<!--
List plausible alternatives to the proposal and explain why the proposal is superior.

This is a good place to incorporate suggestions made during discussion of the RFC.
-->

#### Landscape consideration 

<!--
Landscape of existing solution used as input to conform our alternatives list. 
-->


### Non-functional Requirements

<!--

To complete the proposal with non-functional requirements on how the solution addresses them.

The subsections are the ones we think are a baseline to be considered. If your solution calls for other ones, feel 
free to add them in addition.

Comments in the subsections are examples of questions of problems to address within that section.  
-->


#### Security

<!--
Some questions for this section could be 

- How the solution handles securely e2e the workflow with the user and other systems.
- How we are reducing the risks of the solution to be compromised.  
- How do keep secure the data and other customer assets. 
-->

#### Reliability

<!--
Some questions for this section could be 

- How the solution handles failure and recovers in a context of non-reliable cloud infrastructure (network, compute etc ...)
- How the solution is able to adapt and scale to different processing units (requests, jobs, etc ...)
-->


#### Operations and Observability

<!--
Some questions for this section could be 

- How a developer is able to troubleshoot a known issue within our solution.
- How a developer is able to troubleshoot an unknown issue within our solution.
- How a developer is able to understand how the solution behaves.
-->


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

## Implementation History

<!--
Major milestones in the lifecycle of the RFC such as:
- The first Weave Gitops release where an initial version of the RFC was available.
- The version of Weave Gitops where the RFC graduated to general availability.
- The version of Weave Gitops where the RFC was retired or superseded.
-->