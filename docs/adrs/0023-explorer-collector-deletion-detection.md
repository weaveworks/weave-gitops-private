# 23. Explorer Collector Deletion Detection

Date: 2023-10-09

## Status

Accepted

## Context

We have found that deletions of RBAC objects (`ClusterRole`, `ClusterRoleBinding`, `RoleBinding`, `Role`) are not being detected by Explorer's `Collector` module because the delete events are not being propagated as delete transactions by the `Reconciler` module, and thus are not being processed by Explorer's `Rolecollector` module.

As you can see in the existing Reconciler [code](https://github.com/weaveworks/weave-gitops-enterprise/blob/2fa20cd8360632ebf124d84a681139a906a17350/pkg/query/collector/reconciler/reconciler.go#L70C13-L70C13), if an object being reconciled is not found, an error is returned, and if the type of error is `NotFound`, then a `nil` is returned instead of the error:

```golang
clientObject := r.objectKind.NewClientObjectFunc()
if err := r.client.Get(ctx, req.NamespacedName, clientObject); err != nil {
    return ctrl.Result{}, client.IgnoreNotFound(err)
}
```

Objects which have no finalizers are deleted immediately by the API server, and the deletion reconcile request for these objects is received after the objects have been removed (unlike objects with finalizers, for which we receive a reconcile request before the actual deletion).

As stated in the [Kubebuilder book](https://kubebuilder.io/reference/using-finalizers.html):

> The key point to note is that a finalizer causes “delete” on the object to become an “update” to set deletion timestamp. Presence of deletion timestamp on the object indicates that it is being deleted. Otherwise, without finalizers, a delete shows up as a reconcile where the object is missing from the cache.

Thus, delete transactions for RBAC objects, which have no finalizers by default, are not sent to `Rolecollector`, because we receive a reconcile request for them after such objects are deleted, and a `NotFound` error is returned from the reconcile request without sending a delete transaction.

This is a problem as it means that objects to which Explorer should have no access (after the RBAC objects, granting access to corresponding Kubernetes resources, are deleted), are still displayed in the Explorer UI. Only after restarting the app, the objects are removed from the UI.

Thus, we need to find a way to detect deletion of RBAC objects with no finalizers and send a delete transaction to `Rolecollector` in this case.

After investigation, we propose the following options:

1. Add a finalizer to all RBAC objects.

2. Infer the deletion of a RBAC object if a `NotFound` error is returned when attempting to get an object with a specific `Kind` and create a client object to pass in a delete transaction to `Rolecollector` manually.

3. Use an in-memory structure to keep track of all RBAC objects and store client objects in it (to be able to pass them with the delete transactions) and infer the deletion of a RBAC object if a `NotFound` error is returned for an object found in this structure.

**Option 1 (using finalizers)** would require write access to the RBAC objects, thus users would have to grant Explorer wider permissions than it requires as a read-only service. Besides, we do not want to couple the deletion of a resource in a cluster X with a component, like Collector, living in a cluster Y — to avoid lifecycle dependencies among clusters.

**Option 2 (inferring object deletion from a `NotFound` error and object `Kind`)** is the simplest and the least intrusive of all options, but initially it would only cover the deletion of RBAC objects. If we want to cover the deletion of other objects, we would need to expand the deletion detection logic (for example, to add more `Kinds` to the list of resource kinds which have no finalizers by default) or go with another, more universal, option in the future.

The main drawback of Option 2 is that we have no real client object to pass with a delete transaction to `Rolecollector` and thus we will have to create a client object manually, which mean we will be omitting most of object fields, adding only the minimal fields required for the deletion transaction to be processed by `Rolecollector`. This might lead to issues in the future, if we decide to use more fields to the client object in `Rolecollector` or another module.

**Option 3 (using an in-memory structure to keep track of objects)** is the most comprehensive option, as it will allow us to infer the deletion of an object from a `NotFound` error (similar to Option 2) and pass the whole deleted object with a delete transaction for objects which are not found in the reconcile request.

However, it is the most complex of all options, as it requires us to implement an in-memory structure to store initially detected objects and objects created while the app is running (at least those monitored by Explorer) in memory and track their deletions. This increases memory usage, overcomplicates Explorer's code, and can introduce new caching issues.

The main advantage of Option 3 over Option 2 is that it would allow us to pass the whole object with a delete transaction, but the drawbacks introduced outweigh the benefits for now.

## Decision

After a discussion, we decided to go with Option 2, as it is the simplest and the least intrusive of all options. We will infer the deletion of a RBAC object if a `NotFound` error is returned when attempting to get an object with a specific `Kind` and create a client object to pass in a delete transaction to `Rolecollector` manually. If needed, we can expand the deletion detection logic or switch to another option in the future.

[Tracking issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/2733)

## Consequences

- Tangerine team aligns and knows what should be implemented to fix the issue with RBAC object deletion not propagated to the Explorer UI.
- A user is able to view only those resources in the Explorer UI access to which is granted to them by the RBAC policies.
