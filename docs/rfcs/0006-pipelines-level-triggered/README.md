# Pipeline Controller: Watch Architecture design

## Summary

Currently, the pipeline controller relies on receiving webhook invocations to trigger changes. This has several problems:

**Promotions are attempted at most once**

Flux notifications are not intended to be reliable, and there is one chance to succeed at each promotion. If the endpoint is unavailable, or the promotion fails, then it will not be attempted again. Since the Pipeline status does not record promotion attempts, a missed promotion may be invisible to the user even if attempted.

**You can make the promotion endpoint trigger promotions that are not intended**

The promotion webhook handler acts on the information contained in the URL and in the request body. Only the request body is included in the HMAC, so it's possible to replay a request against a different URL. Since there's a shared key in each target cluster, there's an increased chance a shared key will be compromised, in which situation a notification can be forged.

**It necessitates the addition of several resources beyond just the Pipeline object**

Users must create several resources, usually in leaf clusters, to make notifications work (typically two per environment, a Provider and an Alert). These resources are needed for transmitting update events to the management cluster, where the pipeline controller operates. The notifications usually have their own secrets, and must target a specific URL per environment. Getting these exactly right and in place is onerous.

We aim to engineer a new architecture that simplifies this process while retaining its functionality. We plan to design an architecture that requires less manual configuration, making it more efficient and manageable to operate. By doing so, we hope to reduce the complexities of the workflow and improve the overall user experience.

## Proposal

The controller should rely only on the current state of the pipeline and its apps to decide if needs to promote or not.

To accomplish will take the naive approach of fetching the state of the pipeline, and the app state in all clusters. The downside of that is the pressure we would put on k8s apis of the cluster by potentially make a lot of requests frequently.

To avoid that, we'll rely on the the cache option the `controller-runtime` client provides. When enabled, the client creates Informers to cache the apps data, so when the controller makes a request it will transparently fetch it from the cache instead of calling the cluster's api.


## Design Details

### Clusters Management

To avoid watching clusters that don't belong to any pipeline, the controller will create a set of **used** clusters by listing the pipeline's targets and making sure to create clients only for clusters that belong to at least one pipeline. This way we avoid spending resources on checking clusters that contains no apps of interest.


### Detecting and enacting promotions

In the current architecture, promotions are triggered _at most once_. If a notification is missed, or fails, the promotion will not be attempted again. Flux notifications are not intended to be a reliable medium; and, the pipeline machinery does not record the fact of a notification, so if a promotion fails it does not know to retry it.

The new design has a chance to improve on this by making promotion attempts _exactly once_ (or at least "usually once", since exactly once is in general impossible). By examining the state, rather than relying on being triggered by events, the controller is able to retry if a promotion is missed (the controller was offline when a update happened), or fails.

Given the following infrastructure:

```
dev:
 dev-cluster-1
 dev-cluster-2
staging:
 staging-cluster-1
 staging-cluster-2
production:
  production-cluster-1
```

During the reconcile the controller loops through the `dev`'s targets and check the `latestAppliedRevision` and save it as `latestRevision`, that's the revision the controller will try to propagate across environments.

The controller will have to `wait` modes, `AtLeastOne` where it waits at least a single cluster to be ready with desired revision before proceeding, and `All` where it waits until all clusters are ready.

if the pipeline is set to `AtLeastOne`, check the `staging` environment revisions, if at least one matches the `latestRevision`, it means a promotion to `staging` has already happened and there is no need to act on that environment anymore, so is safe to proceed. Now we check `production` revisions, if not equal to `latestRevision`, promote that revision.

### Promotion  Idempotency
This setup requires the promotion strategies to be idempotent, so there are no collateral effects of running it multiple times.

For example, the current Pull Request strategy needs to be changed to following algorithm:
```
if there is a PR for `app` + `environment`
	if revision equal to `latestRevision`
		do nothing
	else
		change the PR or Close the current and create another one
else
	open the the PR
```

This way we are able to run it in a reconcile loop without worry. Although we should pay attention to caching to avoid spamming git providers api.

This introduces a new problem: how does the controller avoid running a promotion more than once if it hasn't completed yet?

TODO: explain mechanism for deciding when to trigger a promotion
TODO: explain how to make promotions idempotent (NB creating a PR is not the only promotion strategy)

#### Concerns

- with this approach there is a reliance on timestamps to identify the latest revision, if there is any delay in a particular cluster of the first environment while applying a revision, that might lead to the controller trying to promote an older revision.
- we wont be able to support multiple deployments at the same time, when ever pipeline-controller detects a new revision it will try to promote that, meaning that open prs with older revision will be closed/replaced with the new revision.


### Manual approval

At present, the Promotion type includes a field ".Manual" which indicates that a promotion may not proceed until a webhook in invoked. This is a state machine:

 - when a promotion notification is received: if manual approval is not required, the promotion is triggered, else a marker with the expected revision is put in `.Status.Environments[env]`;
 - if an approval webhook is invoked and the marker matches, a promotion is triggered.

An HTTP endpoint accepts POST requests, and extract the pipeline namespace, name, environment, and revision from the path. The handler checks a signature in the header of the request, against a secret given in the Promotion value. So, to set this up, you create a secret with a shared key, and make that key available to any process that needs to do an approval.

TODO: determine whether this machinery can also work with the proposed machinery.
