# 3. Core and enterprise code repos

Date: 2021-07-26

## Status

Proposed

## Context

We currently have code living in 2 repositories weaveworks/wks and weaveworks/weave-gitops.  We also have documentation living in weaveworks/wkp-docs and weaveworks/weave-gitops.  The enterprise code lives in wks, while the opensource/core code lives in weave-gitops.

We will need to share code between core and enterprise (eventually teams).  The UI is running into this need to share implementation code, and the APIs won't be far behind them.

Independent of the UI and API discussion below, we will create a `weave-gitops-pkg` public repository to house code shared between the weave-gitops-* editions.

### Alternatives considered
#### (1) Full microservice approach
All components have their repo and can release independently.  

**Pros**
* all components could release independently
* more shared libraries/packages
* ultimate flexibility for what we want private vs. public

**Cons**
* complicated test matrix
* plugin concept for UI and CLI
* complicated release process 
* maintaining backward compatibility across packages and services

#### (2) Core repo containing complete UI (public), Enterprise repo (private)
UI would be developed in a single code base.  The enterprise features would be grayed out (or a paywall).  The enterprise APIs and optionally CLIs would live in the enterprise repo

**Pros**
* simplify UI development
* core product could give users hints (grayed out buttons) about paid features
* simplified UI testing
* no chance of drift for look and feel of the UI
* we could enable a trial period for enterprise when users download the core UI (would require downloading the enterprise APIs separately)

**Cons**
* a complicated integration test matrix
* updates to an enterprise feature could require us to release a new UI
* UI code is open to the public 


#### (3) UI Repo (private), Core repo (public), Enterprise repo (private)
UI would be developed in a single code base.  The enterprise features would be grayed out (or some sort of paywall).  The enterprise APIs and optionally CLIs would live in the enterprise repo

**Pros**
* (same as whole UI living in core)
* UI completely independent of core and enterprise APIs

**Cons**
* a complicated integration test matrix
* updates to an enterprise feature could require us to release a new UI
* UI code would appear to be abandoned in core
* reduced outside visibility to the UI code

#### (4) Core repo (public), Enterprise repo (private)
The UI would be developed by pulling in the core UI and building on top of it.  i.e., we will have a monolith enterprise UI.  Where possible and practical, the enterprise API services will leverage code from core.  e.g., obtaining temporary Git server API tokens. 

**Pros**
* Core defines the look and feel of the UI, which is leveraged by the enterprise product
* Common reuse pattern and existing architecture 
* Simplified testing matrix 
* An ability for the enterprise product to release at their own pace
* Enterprise can adopt core functionality on their schedule.  Similar to what core does with flux today.
* core and enterprise APIs can release independently

**Cons**
* Enterprise potentially complicated build process
* Coordination between teams


## Decision

We are moving forward with option 4.  We will start to separate mccp cluster create and team workspaces from the weaveworks/wks repo.

## Consequences

The upgrade process, the UI to install a new UI.  i.e., we aren't just turning on new features.
