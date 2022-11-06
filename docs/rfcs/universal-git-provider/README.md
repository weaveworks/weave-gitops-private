# RFC-NNNN A universal git provider for weave gitops 

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

Pepsi is using azure devops repos and they would like to understand the options to extend weave gitops to support it
and when that would happen. At the same time, SAs are asking to extend support to any git provider for  weave gitops to allow
so that we are able to support more enterprise customers beyond github and gitlab.

The flow that we are interested to discover is the creation of a pull request which is used as part of the user journey
within weave gitops enterprise for adding any resource via the UI: add a cluster or application is the most evident examples.

This RFC looks into alternatives on the problem to be able to provide an stable solution with minimal cost to extend, use and maintain.

## Definitions

- Git Provider: company that provides a git-based solution for collaborative and distributed software development. For example
Github, Gitlab, etc.
- Git Hosting: same as Git Provider. 

## Motivation

Once we have a prospect with weave gitops enterprise customers that requires support for git providers others 
than github and gitlab raises the question on whether to extend go-git-providers or to take a different approach 
that decouples the linear costs of supporting a new git provider every time.

### Scope for what we mean by supported git provider  

To scope what we mean for supported git provider, in the context of weave gitops enterprise, is that we are
able to support the Add user journey via Git with ends with an output of a PR being raised in a git configuration repo. 

Creation of a PR functionality it is [defined](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/cmd/clusters-service/pkg/git/git.go#L32)
and [implemented](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/cmd/clusters-service/pkg/git/git.go#L85)
within cluster service leveraging [flux go-git-providers](https://github.com/fluxcd/go-git-providers)

This journey and the git api required to satisfy it is considered mandatory within this RFC. Other git features 
not required to satisfy this journey are considered nice to have. 


### What is the ideal scenario 
An ideal end state means that the recommended solution:

- Provides support for the major git providers we could expect within our enterprise customer base
- Once adopted, there is small to ideally non effort to add another git provider
- Once added a provider, there is no difference for a client using it.
- Once an update to the provider is done, there is a small to non effort to adopt it.


#### What are the major git providers 

While a better authoritative source of data source for this question, we do use the assumption that 
the major git providers within our context whether are hosted or self-hosted  

1) The major git provider services 
   - github 
   - gitlab 
   - bitbucket (or atlassian git services)

2) In addition to the git provider services from the major cloud providers
   - azure devops repos
   - aws codecommit
   - google cloud source repositories

3) other git providers
   - gitea

### Goals

To recommend an approach to extend weave gitops enterprise git provider supported list that meets the requrirements 
sets in the motivation section. 

### Non-Goals

- Any other consideration that goes beyond extending weave gitops git providers capabilities. This includes, git 
 features not required for weave gitops enterprise add user journey. 

  
## Proposal

<!--
This is where we get down to the specifics of what the proposal actually is.
This should have enough detail that reviewers can understand exactly what
you're proposing, but should not include things like API designs or
implementation.

If the RFC goal is to document best practices,
then this section can be replaced with the the actual documentation.
-->


Alternatives

Recommended options by smaller effort of building
1. Extend go git providers with general purpose library like go-scm as facade
2. If facade not allowed for maintainers, create interface in create pull request functionality within wge and to implement non supported providers via go-scm and potentially think on moving out from go-git-providers
3. Migrate off gogit providers to either go-scm or custom wge git provider interface with pull request features

Discouraged options
1. Implement via git



### User Stories

<!--
Optional if existing discussions and/or issues are linked in the motivation section.
-->

### Alternatives

The following alternatives has been discussed

1. Extend go-git-provider by git provider request by using the official git provider sdk
2. Extend go-git-provider using a general-purpose git provider library to do the effort once and support many git providers.
3. To migrate off from go-git-providers to a weave gitops enterprise git interface that is implemented via
   1. generic git provider solution to support many  
   2. using the official git provider sdks by supported git provider
4. To do not operate at git provider api level but at git api level   


### Extend go-git-provider by git provider request by using the official git provider sdk

#### Solution

The solution would be to use a library provider by the git provider. In the case of azure devops would be
https://github.com/microsoft/azure-devops-go-api

PoC not done for this as it seems clear the value that would provide to the problem in terms of pro/cons.
In case of this alternative being selected a poc to manage risks would be encouraged.

##### Evaluation

**pro**
- we would be able to integrate as soon as we have an official library.
- we would potentially have better support for new features, so reduced time to adopt new features.

**cons**
- there is a cost linear to the number of intended git providers in terms of extension and update.

**recommendation**
Given that git is a commodity domain for us, this alternative has very high costs of extension and maintain. It feels
could fit for edge cases where no other cheaper solutions are possible.



### Extend go-git-provider using a general-purpose git provider library to do the effort once and support many git providers.

#### Solution

In order to support azure devops repos within weave gitops enterprise via go git providers, [the following
roadmap](https://miro.com/app/board/uXjVPIBD9Uw=/?share_link_id=307607922383) - as user story mapping format - could be used.

That would involve the following iterations to achieve a **basic azure devops support** where users would
be able to create PRs using centrally managed credentials.

1. to extend go git providers with azure devops. It has an estimation of 1 week effort of development.
2. to integrate go git providers with weave gitops. It has an estimation of less than one week time effort.

Extending the previous iteration, we could get closer to other supported git providers by extending the integration with
the following features

1. to support user access token for azure devops. It has an estimated effort of less than two days of development effort.
2. to support access token via oidc/oauth2. It has an estimated effort of a week.

Notice: that no poc has been done for the last two points so should be considered a guessestimation.

#### Extensible to the prioritised set of git provider

Work discovered https://github.com/enekofb/go-git-providers/pull/3
Using a subset of providers as an example of each category
- cloud provider: azure devops
- major git provider: bitbucket and gitea

with two main stories

- can create a generic client https://github.com/enekofb/go-git-providers/pull/3/files#diff-0b5ca119d2be595aa307d34512d9679e49186307ef94201e4b3dfa079aa89938R13
- can simulate wge git flow https://github.com/enekofb/go-git-providers/pull/3/files#diff-0b5ca119d2be595aa307d34512d9679e49186307ef94201e4b3dfa079aa89938R37

**can create a generic client**

We were able to achieve the target git providers using [scm client factory mechanism](https://github.com/enekofb/go-git-providers/pull/3/files#diff-01b63347d77ed2abddccea29c78c6a09ee835a7adb871ade4d1ba139250e50d1R47).
We had to wrap it to support azure devops as it is [not part of the factory](https://github.com/enekofb/go-git-providers/pull/3/files#diff-01b63347d77ed2abddccea29c78c6a09ee835a7adb871ade4d1ba139250e50d1R43)
Also we could see some potential api inconsistencies https://github.com/enekofb/go-git-providers/pull/3/files#diff-aacc593083df156a8499010330764d81fe4ccd2d4107fd80a7ed2228d2549cadR30


**can simulate wge git flow**

We could do the PR flow for azure devops (already proven) but we could not completed as initially defined for gitea
and bitbucket cloud. The same reason for both of them of jenkins-scm not having fully supported the methods required.
To use other methods has not been explored but based on that we could expect that requests  or contributions
will be required.

For example:
- we could on create branches for gitea and bitbucket https://github.com/enekofb/go-git-providers/pull/3/files#diff-9bfcd2b971052f39f4b1ec7dacb000b3421a50e958f19e71c8a31862f60ca05eR182
- we could not create commits for bitbucket https://github.com/enekofb/go-git-providers/pull/3/files#diff-9bfcd2b971052f39f4b1ec7dacb000b3421a50e958f19e71c8a31862f60ca05eR202

We also find some api inconsistencies between azure devops and the rest
https://github.com/enekofb/go-git-providers/pull/3/files#diff-040a4dfa5eae251c93e6d53a0b46402cc92035031dfc62b6d1589d86587196dcR44

#### Evaluation

at the back of the previous we could get the following pro/cons and summary

**pro**
- integrated most of the required git providers
- consistent api for most of the provider
- simple code to contribute, for example https://github.com/enekofb/go-git-providers/pull/3/files#diff-9bfcd2b971052f39f4b1ec7dacb000b3421a50e958f19e71c8a31862f60ca05eR179

**cons**
- aws codecommit not supported
- google cloud sources repositories
- we cannot assume that supported git providers are fully implemented so we will need to request or contribute it
- we cannot assume that supported git providers are fully integrated with factory method so we will need to request or contribute it
- azure devops inconsistent api

**not evaluated**
- github and gitlab support
- healthiness of jenkins-scm

**summary**

It could be a feasible solution for adopting any git provider but would require work to extend or request
some missing features. There is a delta for integrating with wge PR flow that would depend on the actual support
of jenkins-scm for the git provider. It varies from ones analysed with the common them on gaps around write operations.


### To migrate off from go-git-providers to a weave gitops enterprise git interface that is implemented via

#### Generic git provider solution to support many

##### Solution


https://github.com/jenkins-x/go-scm

This solution would consist of leverage `jenkins-x` library for weave gitops integration to git providers.
Given that is a variation of [extend go git providers](#extend-go-git-providers), what has been said there applies
to this alternative in the context of goals and evaluation.

##### Evaluation 

**pro**

**con**


#### Using the official git provider sdks by supported git provider

##### Solution

TBA

##### Evaluation

TBA
**pro**

**con**


### To do not operate at git provider api level but at git api level

#### Solution

a stated, the alternative would be to do not use a git pr

    Potentially the AzureDevOps issue can be resolved by using libgit2 to push into a new branch, 
    and then giving the user the URL to open the PR themselves: 
    https://dev.azure.com/REPOSITORY/_git/flux/pullrequestcreate?sourceRef=SOURCE-BRANCH&targetRef=TARGET-BRANCH

Discovery not done for this approach.

#### Evaluation

TBA
**pro**

**con**


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