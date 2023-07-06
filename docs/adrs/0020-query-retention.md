# 20. Display Shard Metrics

## Status

Proposal

## Context

We have automated shard deployment creation for Flux controllers

```yaml
apiVersion: templates.weave.works/v1alpha1
kind: FluxShardSet
metadata:
  name: source-controller-shardset
  namespace: flux-system
spec:
  sourceDeploymentRef:
    name: source-controller
  shards:
    - name: shard1
    - name: shard2
    - name: shard3
```

This would automatically create the deployments to process resources tagged for shard1/shard2/shard3.

But, it would be useful to see how our shards are performing, to ensure that they are indeed processing resources.

Hypothetical CLI interaction:

```console
$ gitops get shard metrics source-controller-shardset -n flux-system
# Controller                     | Reconciliations | Errors |
source-controller                |             500 |      1 |
source-controller-shard-1        |              20 |      0 |
source-controller-shard-2        |             100 |      0 |
source-controller-shard-3        |               0 |      0 |
```

We could easily see from this, that shard-3 is not processing resources, which may or may not be expected.

## Decision

For each controller associated with the shard-set, this would grab metrics from each, and output how many reconciliations they have performed.

We can do this by getting the shard-set, loading the inventory, and iterating over the generated controllers.

We can then go to the metrics endpoint on the Flux controllers `:8080/metrics` and parse the Prometheus metrics to figure the data out.

The data from a Flux source-controller looks like this:

```
# HELP controller_runtime_reconcile_total Total number of reconciliations per controller
# TYPE controller_runtime_reconcile_total counter
controller_runtime_reconcile_total{controller="bucket",result="error"} 0
controller_runtime_reconcile_total{controller="bucket",result="requeue"} 0
controller_runtime_reconcile_total{controller="bucket",result="requeue_after"} 0
controller_runtime_reconcile_total{controller="bucket",result="success"} 0
controller_runtime_reconcile_total{controller="gitrepository",result="error"} 14
controller_runtime_reconcile_total{controller="gitrepository",result="requeue"} 1
controller_runtime_reconcile_total{controller="gitrepository",result="requeue_after"} 1143
controller_runtime_reconcile_total{controller="gitrepository",result="success"} 1
controller_runtime_reconcile_total{controller="helmchart",result="error"} 0
controller_runtime_reconcile_total{controller="helmchart",result="requeue"} 0
controller_runtime_reconcile_total{controller="helmchart",result="requeue_after"} 2670
controller_runtime_reconcile_total{controller="helmchart",result="success"} 0
controller_runtime_reconcile_total{controller="helmrepository",result="error"} 14
controller_runtime_reconcile_total{controller="helmrepository",result="requeue"} 0
controller_runtime_reconcile_total{controller="helmrepository",result="requeue_after"} 977
controller_runtime_reconcile_total{controller="helmrepository",result="success"} 0
controller_runtime_reconcile_total{controller="ocirepository",result="error"} 3
controller_runtime_reconcile_total{controller="ocirepository",result="requeue"} 0
controller_runtime_reconcile_total{controller="ocirepository",result="requeue_after"} 180
controller_runtime_reconcile_total{controller="ocirepository",result="success"} 0
```

**NOTE**: To get the data from the CLI, we will likely need a [Pod Proxy-based approach](https://github.com/weaveworks/gitopssets-controller/blob/main/pkg/cmd/fetcher.go).

## Alternatives

We can't be sure where the data would be stored, so saying that we'll access `Grafana` won't work for all cases.

The cheapest thing to do, is to query the Deployments, this doesn't preclude any other solutions.

The data should always be available from the Flux controller deployments, if not, we would not be able to get any metrics.

## Reuse

At its core, we can implement a function:

```go
type ShardMetric struct {
  Deploy types.NamespacedName
  Reconciliations int64
  Errors int64
}

type ShardMetrics struct {
  Source types.NamespacedName // References the source
  Deployments []ShardMetric
}

func GetMetricsForShardSet(ctx context.Context, shardSet templatesv1.ShardSet, client Fetcher) (*ShardMetrics, error) {
    // load the shardset
    // walk the deployments in the inventory fetching their metrics
    // fetch the metrics for the source deployment
    // return the combined results
}
```
The `Fetcher` is basically an HTTP client, we can do this in-cluster directly (so for example, executing from the UI) or via a Pod Proxy client for execution from the CLI.

## Security

This does not involve storing data or access to secrets.

It does require access to the `kubernetes-api` from the CLI (or a proxy or something), but that is somewhat mitigated if implemented in the UI.

There _may_ need to be Network Policies in place to allow access to the controller metrics, but generally, access to the read-only Prometheus metrics is permissible in organisations.
