# 12. Architecture direction of travel 2022 / 2023

## Status

Proposed

## Context

Over the past months, we have been working in trying to get weave gitops to a point that satisfies two primary business purposes

- an OSS product to simplify flux users adoption of gitops
- an enterprise product that builds on top of the OSS to provide the enterprise-grade solution

During this effort, as product engineering, we have received the messages of looking at

- each weave gitops capability to have an OSS and Enterprise story.
- to have laser focus on delivering enterprise features to enable sales.

In practice, when trying to materialize these two points, we have always found that either architecture or release process (or both) have been a constraint resulting in having to choose from either one of them.


## Decision

Our architecture and delivery process should help us to achieve our business goals. We should not be trapped in a situation where teams need to take expensive tradeoffs. An example of it is the two codebases vs single codebase discussion. In that sense, if the solution that helps us achieve our business goals is to have a single codebase, we should consider it as an option.

Any exploration around this topic should be progressive, and to have into consideration our current business context, where we will not be able to stop contributing towards our objectives around Weave Gitops Enterprise capabilities.


## Consequences

To set expectations across product engineering on what we could do to improve our current architecture limitations around Weave Gitops Enterprise and OSS.

To set expectations across product engineering on the constraint that we need to consider while doing this effort.
