# RFC-0004 extend git providers beyond github and gitlab 

<!--
The title must be short and descriptive.
-->

**Status:** provisional

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-11-07

**Last update:** 2022-11-07

## Summary

Pepsi is using azure devops repos and they would like to understand the options to extend weave gitops to support it
and when that would happen. At the same time, Solutions Architects would like to see weave gitops enterprise 
supporting any git provider that an enterprise customer could be using. 

Currently, weave gitops enterprise uses integration with git providers for mainly creation of a pull request 
as part of the add user journey: add a cluster or application is the most evident examples. This is the scope of supporting
that we are interested. 

This RFC looks into alternatives to address this problem and recommends the one with minimal cost to extend, use and maintain. 

## Definitions

- Git Provider: service or product that provides git repository management and other git features for collaborative and distributed software development. 
For example Github, Gitlab, etc.
- Git Hosting: same as Git Provider. 

## Motivation

Once we have a prospect with weave gitops enterprise customers that requires support for git providers others 
than github and gitlab raises the question on whether to extend go-git-providers or to take a different approach 
that decouples the linear costs of supporting a new git provider every time.

### What we mean by supported git provider  

To scope what we mean for supported git provider, in the context of weave gitops enterprise, is that we are
able to support the Add user journey via Git with ends with an output of a PR being raised in a git configuration repo. 

Creation of a PR functionality it is [defined](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/cmd/clusters-service/pkg/git/git.go#L32)
and [implemented](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/cmd/clusters-service/pkg/git/git.go#L85)
within cluster service leveraging [flux go-git-providers](https://github.com/fluxcd/go-git-providers)

This journey and the git api required to satisfy it is considered mandatory within this RFC. Other git features 
not required to satisfy this journey are considered nice to have.

### What is the ideal end state for git providers support

An ideal end state means is the one that 

- Provides support for the major git providers we could expect within our enterprise customer base.
- Once adopted, there is small to ideally non effort to add another git provider.
- Once added a provider, there is no difference for a client using it.
- Once an update to the provider is done, there is a small to non effort to adopt it.


#### What are the major git providers 

While a better authoritative source of data source for this question, we do use the assumption that 
the major git providers within our context are   

1) The major git provider services 
   - github 
   - gitlab 
   - bitbucket (or atlassian git services)
2) In addition to the git provider services from the major cloud providers
   - azure devops repos
   - aws codecommit
   - google cloud source repositories
3) And finally other known git providers
   - gitea

### Goals

- To recommend an approach to extend weave gitops enterprise git provider supported list that meets the requirements 
sets in the motivation section. 

### Non-Goals

- Any other consideration that goes beyond extending weave gitops git providers capabilities. This includes, git 
 features not required for weave gitops enterprise `add` user journey. 

  
## Proposal

The following alternatives have been considered:

1. Extend go-git-provider by git provider request by using the official git provider sdk
2. Extend go-git-provider using a general-purpose git provider library to do the effort once and support many git providers.
3. To migrate off from go-git-providers to a weave gitops enterprise git interface that is implemented via
   1. generic git provider solution to support many
   2. using the official git provider sdks by supported git provider
4. To do not operate at git provider api level but at git api level

With the following recommendation:

Given that git domain for weave gitops enterprise it is a commodity. We consider it a commodity as we require it (like kubernetes clusters)
but does not provide wge a sustained competitive advantage as it could be easily replicated by competitors. Therefore, a strategy 
to leverage git capabilities to an existing solution is preferred over building our own. 

In that sense, a solution based on a generic git provider like [jenkins/go-scm](https://github.com/jenkins-x/go-scm)
or [drone/go-scm](https://github.com/drone/go-scm), even has been proven it would require contributions, 
is the best alternative to achieve the largest git-providers support with smaller building effort. 
In that sense, it is preferred over building each git provider integration ourselves. 

Given the previous statement, the alternative `#2 of extending go-git-providers with go-scm like solution` would be 
the preferred solution. It has been proven technically feasible under the [azure devops poc](https://github.com/weaveworks/weave-gitops-enterprise/issues/1704).
The recommendation would be to **just extend go-git-providers api required to support the `add` or `pull request`** wge user journey. 
To implement other api endpoints would be out of this recommendation.

A [question](https://github.com/fluxcd/flux2/discussions/3292) has been raised to go-git-providers to understand the feasibility of this approach. 

### FAQ

#### What to do in case of go-git-providers solution is not feasible 

In case it won't be feasible, an alternative recommendation is provided:

1. To create within weave gitops enterprise an interface around the PR user journey that abstracts it usage from go-git-providers.
2. To use a factory-like pattern by git provider where:
   1. For go-git-providers supported git providers, like github or gitlab, to implement this interface via go-git-providers.
   2. For other git providers, implement it via go-scm.

Given that this solution increases the complexity on weave gitops enterprise side, an action to make this sustainable
should be taken by either 1) reducing exposure to go-git-providers or 2) to contribute the git provider support for go-git-providers.

#### Reasons to do not recommend other solutions

The main reason to discard any of the previous solutions is that it would require, for any of them, longer
development effort to achieve the same supported git providers.

The unique solution where the previous statement is not necessarily true is `#4 to operate at git level`. This
solution is mainly discouraged due to the tradeoffs that carry on, in particular the impact on the user experience. 
We are bounding a user sync call like `create a pull request` to a `git clone` operation to work with remote repositories.
This operation is dependent of the size of the repo therefore in terms of latency. This would have a direct impact on 
the user experience. Mitigations could be done to this problem, but it would require a more complex solution or extra infrastructure.
In any case, any the other alternatives would be preferred over this approach. 

#### Why investing or not in go-git-providers

As mentioned in the proposal, as weave gitops enterprise, investing in git providers does not seem strategic.
Only if there are other reasons (business or technical) not scoped  in this RFC, there could be strategic value on contributing. 
An example of it could be the willingness to create from go-git-providers de-facto solution in the space. Currently, 
there is no a clear solution in the space that has a complete support of all the major git providers. 

### Alternatives

The following alternatives has been discussed

1. Extend go-git-provider by git provider request by using the official git provider sdk
2. Extend go-git-provider using a general-purpose git provider library to do the effort once and support many git providers.
3. To migrate off from go-git-providers to a weave gitops enterprise git interface that is implemented via
   1. generic git provider solution to support many  
   2. using the official git provider sdks by supported git provider
4. To do not operate at git provider api level but at git api level   

This section illustrates and analyses them.

### Extend go-git-provider by git provider request by using the official git provider sdk

#### Solution

The solution would be to use a library provider by the git provider. In the case of azure devops would be
https://github.com/microsoft/azure-devops-go-api. In the context of gitea would be
https://pkg.go.dev/code.gitea.io/sdk/gitea.

PoC not done for this as it seems clear the value that would provide to the problem in terms of pro/cons.
In case of this alternative being selected a poc to manage risks would be encouraged.

##### Evaluation

**pro**
- Finer supports for the git provider in terms of features as it would use an official library.
- Time to adopt new features decreases as it is assumed would appear first in the official library. 

**cons**
- Cost to extend the solution linear to the number of git providers to support.
- Cost to maintain an existing provider linear to the number of git providers to support.

### Extend go-git-provider using a general-purpose git provider library to do the effort once and support many git providers.

#### Solution

This solution has been discovered as part this [issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/1704)
where a generic library like [jenkins-x/go-scm](https://github.com/jenkins-x/go-scm) has been used to extend 
the list of supported git provider to go-git-providers via a facade design pattern. 
An example of the poc could be seen in this [pr](https://github.com/enekofb/go-git-providers/pull/3/files).

#### Evaluation

**pro**
- Integrates most of the main git providers. 
- Provides a consistent api. 
- Simple to contribute, for example https://github.com/enekofb/go-git-providers/pull/3/files#diff-9bfcd2b971052f39f4b1ec7dacb000b3421a50e958f19e71c8a31862f60ca05eR179
- we dont need to change weave gitops enterprise api

**cons**
- Neither aws nor google cloud are yet supported.
- We cannot assume that supported git providers are fully implemented, so we will need to request or contribute it
- We cannot assume that supported git providers are fully integrated with factory method, so we will need to request or contribute it
- Azure devops has an inconsistent api 


### To migrate off from go-git-providers to a weave gitops enterprise git interface that is implemented via

#### Generic git provider solution to support many

##### Solution

This solution would consist of leverage [jenkins-x/go-scm](https://github.com/jenkins-x/go-scm) library for weave gitops integration to git providers.
Given that is a variation of [extend go git providers](#extend-go-git-providers), what has been said there applies
to this alternative in the context of goals and evaluation.

##### Evaluation 

**pro**
- Integrates most of the main git providers.
- Provides a consistent api.
- Simple to contribute, for example https://github.com/enekofb/go-git-providers/pull/3/files#diff-9bfcd2b971052f39f4b1ec7dacb000b3421a50e958f19e71c8a31862f60ca05eR179

**cons**
- Migration is needed so higher cost of adopting this solution vs other alternatives that does not require changes on wge api. 
- Neither aws nor google cloud are yet supported.
- We cannot assume that supported git providers are fully implemented, so we will need to request or contribute it
- We cannot assume that supported git providers are fully integrated with factory method, so we will need to request or contribute it
- Azure devops has an inconsistent api

#### Using the official git provider sdks by supported git provider
//TODO to add with kevin
##### Solution
TBA

##### Evaluation
TBA
**pro**

**con**


### To do not operate at git provider api level but at git api level

#### Solution

As stated, the alternative would be to do not use a git pr

    Potentially the AzureDevOps issue can be resolved by using libgit2 to push into a new branch, 
    and then giving the user the URL to open the PR themselves: 
    https://dev.azure.com/REPOSITORY/_git/flux/pullrequestcreate?sourceRef=SOURCE-BRANCH&targetRef=TARGET-BRANCH


#### Evaluation

This solution has a structural limitation: it would require to clone the remote repo before we are able
to create branch and commit. This means that we are bounding a user sync call like `create a pull request` to a `git clone` operation.
This operation is dependent of the size of the repo with a direct impact on the user experience going from range of a few seconds (acceptable)
to minutes (non acceptable). Mitigations could be done to this problem, but it would require a more complex solution or extra infrastructure.
This complexity is what are leveraging to the git providers by using their apis so a solution in this sense would be preferred.
This solution should be considered last alternative. 

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

Not implemented
<!--
Major milestones in the lifecycle of the RFC such as:
- The first Flux release where an initial version of the RFC was available.
- The version of Flux where the RFC graduated to general availability.
- The version of Flux where the RFC was retired or superseded.
-->