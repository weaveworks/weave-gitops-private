# 17. Pipeline pull request promotions security review

Date: 2023-02-16

## Status

Proposed

This ADR supersedes parts of [ADR 13](0013-pipelines-promotions.md).

## Context

ADRs [11](0011-pipelines.md) and [13](0013-pipelines-promotion.md) define an API for application delivery pipelines 
and promotions from one environment to another. That API requires users to store Personal Access Tokens for the respective 
Git provider on their clusters (see [RFC 3 for details](../rfcs/0003-pipelines-promotion/execute-promotion.md#security)).

Whereas it is a simple solution to implement and certainly has contributed to gear product demos, compromised personal access 
tokens is a very present risk factor in attacks suffered by [git providers](https://astrix.security/3-oauth-attacks-in-6-months-the-new-generation-of-supply-chain-attacks/). 

This ADR records the actions and direction set for pipelines to address this wider enterprise usage perspective. 

## Decision

The following actions were decided:

1. To extend the [existing documentation](https://docs.gitops.weave.works/docs/pipelines/promoting-applications) with enough context for pipeline users
to understand, and help to manage the risks of the existing approach.    
2. To review the current solution to find a better balance between easy to use and security that makes feel more comfortable.  

### Extend Documentation 

The following [issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/2402) was created to include and extend on some of the following points:

- Security implications of using a long-lived access token.
- How to restrict access to that token, so that only the service account that uses it can read it.
- Provide clear guidance on how to create a fine-grained token with as little scope as necessary.
- Clarifying what we use the token for, so that folks can make informed decisions about how to create it 
(for example, if you say "Every Pull Request will show up as being created by the user behind the access token", folks might think "Hmmm..., I don’t think that should be my token").


### Review solution  
TBA from https://github.com/weaveworks/weave-gitops-private/pull/110/files#r1115794629  

## Consequences

- Pipeline users are in a safer place while being able to leverage the capability.  
- We are in a better place as product xxx
- 