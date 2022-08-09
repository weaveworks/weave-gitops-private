# 11. Weave Gitops business model translated into codebase

## Status

Proposed

## Context

Weaveworks [business model](https://docs.google.com/presentation/d/1zagnq6LEwuzmPznvmdltUCoXnKzsfvRLvy7bLDlR8W4/) 
based on converting oss users into paying customers via enterprise features.

At the back of this strategy, we are building Weave Gitops OSS and Weave Gitops Enterprise where
- The oss project is expected to have external contributions and its own release cycle.
- The enterprise product should be a set of addons to oss.
- The oss should support addons.
- Addons maybe paid or OSS

In terms of code bases, 
- There is no hard requirement on having paid addons as closed source

//TODO add other context notes

As we dont have a known record for the translations of the previous requirements into codebases. This ADR tries
to look back to the decision to record the context and consequences so it is visible to anyone. 

## Decision

At the back of our needs OSS / Enterprise, it was decided to have two code bases:
- [Weave Gitops Enterprise](https://github.com/weaveworks/weave-gitops-enterprise) for paid addons with closed source.
- [Weave Gitops](https://github.com/weaveworks/weave-gitops-enterprise) for contributions, OSS addons with open source.

## Consequences

- //TODO list benefits 
- // TODO list tradeoffs used during the analysis

## Monitor
// identify at the back of the consequences, how to evaluate over the fi 

## Metadata

**Date** 2022-08
**Approval Date**
**Authors**
- Eneko
- Kevin/ Steve / Mazz / James / Liz / Alexis?

## References

Example of conversations that motivated the ADR  
- https://weaveworks.slack.com/archives/C03QNK53W68/p1659690135054569
- https://weaveworks.slack.com/archives/CMDJFD3P0/p1659693285668129
- https://weaveworks.slack.com/archives/CGRMRRJCC/p1659717410323449


