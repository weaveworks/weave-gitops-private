# 24. Intermediate Explorer Object Statuses

Date: 2023-11-24

## Status

Accepted

## Context

A [suggestion](https://github.com/weaveworks/weave-gitops-interlock/issues/482) was made to add some indication ("an amber traffic light") for intermediate resource states when a resource has not failed but is not ready yet either.

The issue is that when a resource is in an intermediate state, e.g. "reconciling", or requires a further user action, or is temporarily suspended, it is not clear to the user what is going on. The user may think that the resource is in a failed state when they see a red exclamation sign indicator in Explorer UI, when in fact it is not.

To provide more clarity and capability to evaluate the current state of the resources at a glance at Explorer UI to the users, it was suggested to add some indication for intermediate resource states, e.g. the "amber traffic light" indicator.

After initial research and a discussion, based on objects statuses, currently displayed in the UI outside of Explorer, the following options were suggested:

1. Add a catch-all/umbrella `InProgress` status with a `Busy` or `Reconciling` visual status indicator for Explorer objects which are currently in intermediate states (e.g. `Reconciling`, `PendingAction`, `Suspended`).

2. Add a distinct status and corresponding visual indication for each of the intermediate states (e.g. `Reconciling`, `PendingAction`, `Suspended`, etc.) which are of interest to the user.

Non-Explorer parts of the UI use the following [list of computed object statuses](https://github.com/weaveworks/weave-gitops/blob/0a3a61224efc119111f29ca939fde58412dc3090/ui/components/KubeStatusIndicator.tsx#L18), computed on demand (before displaying the object status in the UI):

```
export enum ReadyType {
  Ready = "Ready",
  NotReady = "Not Ready",
  Reconciling = "Reconciling",
  PendingAction = "PendingAction",
  Suspended = "Suspended",
  None = "None",
}
```

The list of statuses is based on the outcomes of several previous frontend issues (for example, the following [PR description](https://github.com/weaveworks/weave-gitops/pull/2837)) and was composed on the ad hoc basis.

It was suggested to add the same intermediate object statuses (`Reconciling`, `PendingAction`, and `Suspended`) to the backend for now and treat the backend as the single source of truth for the intermediate object statuses, to make sure that the intermediate statuses are consistent across the UI.

Standardizing non-intermediate object statuses (e.g. `Failed` or `NotReady`) across the frontend and the backend will require further investigation and is beyond the scope of this ADR.

**Option 1 (using a catch-all `InProgress` status)** is the simplest of the two options, but it is not very informative, as it does not provide any details on the state of the object, besides the fact that it is in one of its intermediate states.

Users will have to check the object's Details page to get more details on the state of the object and to decide if any action is required from them.

Besides, if we decide to use a catch-all `InProgress` intermediate status in Explorer, we will not be able to use the backend as the single source of truth for the object statuses, because intermediate statuses, used in Explorer, will be different from statuses used in the frontend in non-Explorer UI.

**Option 2 (using distinct statuses for each of the intermediate states)** is more informative, as it provides more details on the state of the object, besides the fact that it is in one of its intermediate states.

Users will be able to get a better idea on the state of the object at a glance at Explorer UI and to decide if they need to take any action or if the object's currently intermediate state is expected and can be ignored safely.

In addition, if we decide to use the same intermediate statuses as those, currently used in the frontend, in Explorer, we will be able to use the backend as the single source of truth for the object statuses throughout the whole UI.

## Decision

 We decided to go with **option 2 (using distinct statuses for each of the intermediate states)**, as it will provide more detailed info on the state of the object than option 1.
 
 The following intermediate statuses for objects, listed in Explorer UI, will be added:
- `Reconciling` — for objects which are being reconciled.
- `Suspended` — for objects which are suspended (that is, they are not reconciled automatically on configuration changes).
- `PendingAction` — for objects which are waiting for a user action.

The list of statuses can be expanded in the future, if needed.

Each of the statuses will be computed on a case-by-case basis, depending on the object's `Kind` and values of the object's `Conditions` field and other fields, similar to how it is currently done in the frontend to provide visual indication in non-Explorer parts of the UI.

Besides, each of these statuses will have a corresponding icon, which will be displayed in the UI, similar to how object statuses are currently displayed in the non-Explorer parts of the UI.

## Consequences

- Tangerine team aligns and knows what should be implemented to add more detailed indication of intermediate object states to the Explorer UI.
- Status business logic is defined in the backend (instead of the frontend where it is currently defined) which is treated as the single source of truth for the object statuses.
- Users are able to get a better idea on the state of resources in the Explorer UI and to decide if they need to take any action based on the current object status.
