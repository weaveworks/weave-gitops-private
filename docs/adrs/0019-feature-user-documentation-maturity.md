# 19. Feature maturity expectation in user documentation 

Date: 2023-04-XX

## Status

Proposed

## Context

In the context of a new product feature, we usually close (if not earlier) its delivery by adding user documentation. In the
context of Weave GitOps is its [documentation website](https://docs.gitops.weave.works/docs/intro/).  

The user documentation helps a user onboarding to a new feature, among other concerns, to:
- Understand the value the feature provides to the user. 
- How to get started or day 1 experience.
- How to do other scenario like operations or day 2 experience.

However, in the context of adopting a new solution, there is usually a concern of building up confidence and managing risks.
This concern, is not necessarily consistently addressed in our documentation, where sometimes we flag that info with documentation 
or a warning signaling it.

![alpha-warning.png](images%2Falpha-warning.png)

Therefore, we leave the user to form an opinion and define how that adoption itinerary looks like without guidance. That opens
(at least) two scenarios:

1. If there is a match between user expectations about maturity is and the actual maturity, there wont be an misalignment. 
2. If not, that misalignment would show up in different ways: from "hey, this feature is not yet super mature" or "the app is crashing in production impacting XYZ revenue". 

This ADR decides on the previous problem statement based on the following potential next steps:

1. Do nothing, this is not an important decision to take or we dont want to take it because XYZ.
2. Do something acknowledging that we want to guide users in their adoption journey. In case we think we should do something:
      1. Follow a similar approach to [api version lifecycle](./0014-api-versioning-lifecycle.md)
         - maturity levels of Alpha, Beta, Stable with a baseline definition of these levels
         - guidelines on how to communicate the maturity without disincentive users to try out
         - other points
      2. Another approach TBD

## Decision

TBA after discussion and agreements

## Consequences

TBA after discussion and agreements
