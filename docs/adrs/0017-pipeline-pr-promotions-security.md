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

Out of reviewing the [solution](https://github.com/weaveworks/weave-gitops-private/pull/110#discussion_r1115794629), 
we have decided to iterate our pull request promotions strategy flow as follows:

1. To add a user-driven pull request promotion flow.
2. To keep the existing pull request creation flow. Increase visibility on its usage to help users better understand its runtime status.  
3. To recommend the user-driven pull request promotion over other ones as it meets a better easy to use / security balance.
4. To consider implementing other most costly solutions out of the customer feedback or future needs. it includes GitHub App like integration with token exchange.    

#### Add a user-driven pull request promotion flow

It would be to follow the same authN/authZ approach to the add application user flow already existing in weave gitops enterprise.
In this flow, we would generate the short-lived access token that would allow pipeline controller (or wge backend if considered best) to create the pull request.
To enhance the user experience the access token could be cached but never stored. This experience would extend the 
existing manual promotion experience.

#### To keep the existing pull request creation flow. Increase visibility on its usage to help users better understand its runtime status.

Surface in the UI the information that allows to determine 
- the user behind the token.   
- when the token was last used and whether it is still valid.

We could use this [api](https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28#get-the-authenticated-user).

## Consequences

- Pipeline users better understand the risks of using access tokens for promotions and ways to reduce that risks.
- Pipelines users are able to have full control on promotions while leverage pull request creation automation without credentials stored. 
- Pipelines users are in a safer place overall.
- We provide are in a better place too.