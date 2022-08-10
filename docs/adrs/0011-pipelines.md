# 11. Continuous Delivery Pipelines in Weave GitOps

## Status

Proposed

## Context

As part of Weave GitOps, Sunglow team is working on delivering Continuous Delivery Pipelines based in the following 
[initiative](https://www.notion.so/weaveworks/CD-Pipeline-39a6df44798c4b9fbd140f9d0df1212a)

The past week has been used for doing discovery on designing a solution that could help us working in the context
of the two main milestones named as (0.1) and (1.0). The design work has been documented in 
[the following RFC](/Users/enekofb/projects/github.com/weaveworks/weave-gitops-private/docs/rfcs/0001-pipelines/README.md)

This ADR writes down the decision taken by the team regarding which alternative to start with and the consequences 
and tradeoffs done for that decision. 

## Decision

Pipelines implementation will start by using the `hybrid` solution and evolve the solution accordingly to emerging requirements
(if needed). This solution has been decided as it offers a balanced approach in terms of 
- simplicity: to start shipping towards 0.1 without the complexity that other solutions like `full crd` could impose in terms of machinery.   
- performance: provides a better query path experience than solutions like purely `label` alternative.
- flexible for the unknowns: it is flexible enough to reduce risks towards 1.0. 

We will be taking an enterprise-first strategy where first iteration will be 
on [weave gitops enterprise](https://github.com/weaveworks/weave-gitops-enterprise) for then upstream it to 
[weave gitops OSS](https://github.com/weaveworks/weave-gitops). We have decided to go in this direction due the 
impediments that our architecture has for doing the other way around, OSS first then Enterprise.

## Consequences

To have an enterprise-first approach, has an impact on OSS users that won't see a delay on when the capability will be available.

To have an enterprise-first approach reduces risk to deliver against our main engineering objective of
[OKR#2: Add features that drive Weave GitOps enterprise customer conversion](https://docs.google.com/presentation/d/104b4ThKT78rznucxw6kMsrRY0OnEn6XanSvb039TA-g/edit#slide=id.gd1cb39726e_19_8)


## Metadata

**Date** 2022-08-09

**Approval Date** 2022-08-1x

**Authors**

- Ahmed
- Antony
- David
- Eneko
- Jordan
- Luiz
- Max
- Russell
- Yiannis




