# RFC-0003 Pipelines security context

<!--
The title must be short and descriptive.
-->

**Status:** provisional

<!--
Status represents the current state of the RFC.
Must be one of `provisional`, `implementable`, `implemented`, `deferred`, `rejected`, `withdrawn`, or `replaced`.
-->

**Creation date:** 2022-07-29

**Last update:** 2022-08-25

## Summary

Define the security context where pipelines would live one. We just want to ensure that we have a proper security 
approach for pipelines from the 
- user perspective
- platform perspective

## Motivation

1. Pipelines enables delivering apps to environments.
2. Environments could span different deployment targets.  
3. Deployment targets has a defined access model given by either RBAC or Tenancy. 

This RFC goes into ensure that pipelines provides good security properties for users and platform 

### Terminology

TBA

### Goals

<!--
List the specific goals of this RFC. What is it trying to achieve? How will we
know that this has succeeded?
-->
- Define security model for pipeline users.
- Define security model for pipeline components.

### Non-Goals

<!--
What is out of scope for this RFC? Listing non-goals helps to focus discussion
and make progress.
-->

* Automatic promotion of an application through the stages of a pipeline is not part of this proposal but the proposal should allow for building that on top.

## Proposal

Scenario: 

We have two tenants
- `search`  that provides the apps for discoverability within the orgs business model
- `billing` that provides customer billing related capabilities for the orgs business model

And we have two types of organisations

- org-shared-environments where we have a single dev, staging prod environmentn for running all applications
- tenant-segementated where we have  search-prod and billing-prod environments for running applications

Both organisation are using pipelines for wge with 
- tenants for search and billing
- clusters managed by WGE

The user stories that we want to run through is that

1. as pipeline component I have the right access model for achieving my expected duties. I follow least priviledged model.
My expected where pipeline components are
   1. as pipeline ui
   2. as pipeline backend
   3. as pipeline controller
2. as pipeline user, i cannot access resources i dont have permission
3. as pipeline user, i cannot create pipelines for resources i have not permissions 

## Scenario A: shared environment

Management Cluster:
- search pipeline exists 
- billing pipeline exists
Dev, Staging, Prod: 
- serach app deployed as helm release in each of the environmnet 
- app deployed as helm release in each of the environmnet
- billing a
- search app deployed in 
- - search app deployed in
Staging:
Prod:



## Scenario B: segmentation by tenant 

In the context of the first scenario we have the three stories are 






- 
 




