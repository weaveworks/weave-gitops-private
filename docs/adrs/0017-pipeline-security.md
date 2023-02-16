# 1. Record architecture decisions

Date: 2023-02-16

## Status

Proposed

This ADR supersedes parts of [ADR 13](0013-pipelines-promotions.md).

## Context

ADRs [11](0011-pipelines.md) and [13](0013-pipelines-promotion.md) define an API for application delivery pipelines and promotions from one environment to another. That API requires users to store Personal Access Tokens for the respective Git provider on their clusters (see [RFC 3 for details](../rfcs/0003-pipelines-promotion/execute-promotion.md#security)). This requirement brings with it several security and user experience issues:

- In Enterprise GitHub installations, the token lifecycle is linked to the user session expiry. This means that as soon as the user's session expires, the access token also expires and is not usable, anymore.
- It is very hard to refute changes made with a token, and it requires to be a writable token.
- We recommend to customers to use a bot account, which makes nonrepudiation even harder to enforce.
- Documentation around the feature must be accompanied with clear warnings on the security implications of that practice. However, users are particularly.
- Leaked personal access tokens have led to security incidents in the past and we should not advocate to use them for long-lived actions such as storing them in-cluster.
- Fundamentally, storing "secure tokens" in plaintext in clusters is not a great idea.

This ADR discusses alternatives to the chosen solution and lays out a way forward to replace the use of long-lived access tokens for the use case of promoting applications through environments using pull/merge requests.

## Decision

### Documentation improvements

- We will change the [existing documentation](https://docs.gitops.weave.works/docs/pipelines/promoting-applications/#create-credentials-secret) and add a big red warning about the security implications of using a long-lived access token.
- We will add documentation about how to restrict access to that token, so that only the service account that uses it can read it.
- We will add documentation to provide clear guidance on how to create a fine-grained token with as little scope as necessary.
- We will add documentation clarifying what we use the token for, so that folks can make informed decisions about how to create it (for example, if you say "Every Pull Request will show up as being created by the user behind the access token", folks might think "Hmmm..., I don’t think that should be my token").

### Design improvements



## Consequences

tbd
