# 19. Define how to setup maturity expecteations for users in the documentation 

Date: 2023-04-XX

## Status

Proposed

## Context

In the context of a new product feature, we usually close (if not earlier) the delivery by adding its user documentation, that in the
context of weave gitops is its documentation website https://docs.gitops.weave.works/docs/intro/.  

The user documentation helps any user onboarding to a new feature to
- understand which problem address
- how to get started with the feature or day 1 experience
- how to do other advance scenario, operations or day 2 experience
among other concerns. 

However, in the context of adopting a new technology or solution, there is usually a process to build up confidence
and uses cases to help managing the different risks associated. In the context of our documentation, we dont 
provide consistently information to user helping them to manage those risks and expectations so we leave 
to them to form an opinion and define how that adoption iterinerary looks like without guidance.

That opens two scenarios:

1. if there is a match between what the user expectations is about maturity and the actual feature mature there wont be an missalingment. 
2. if not, that misalignment would show up in different ways: from "hey, this feature is not yet super mature" or "the app is crashing in production impacting XYZ revenue" 

There are some potential actions to do here:

1. Do nothing, this is not an important decision to take or we dont want to take it because XYZ
2. Do something acknowledging that we want to guide users in their adoption journey. In case we think we should do something:
      1. Follow a similar approach to [api version lifecycle](./0014-api-versioning-lifecycle.md)
         - maturity levels of Alpha, Beta, Stable with a baseline definition of these levels
         - guidelines on how to communicate the maturity without disincentive users to try out
         - other points
      2. Another approach

## Decision

TBA after discussion and agreements

## Consequences

TBA after discussion and agreements
