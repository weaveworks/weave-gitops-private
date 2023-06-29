# 19. Retain objects after they have been removed from the cluster

## Status

Proposal

## Context

In certain cases, it is useful to keep objects after they have been removed from the cluster. The primary example would be `Event` objects, which are often deleted after an hour. These events can be critical for troubleshooting issues on the cluster, and in the case of `policy-agent`, the primary source of information on certain controllers running in the cluster.

Given that we have a cacheing mechanism for objects, we should be able to retain `Events` for longer than an hour and surface them in the `Explorer` UI.

## Decision

The basic design is as follows:

1. We add a `RetentionPolicy` to the `configuration.ObjectKind`. This type can be a `time.Duration` for now.

2. We add a `KubernetesDeletedAt` field to the `models.Object` so that we differentiate between the internal `DeletedAt` timestamp field.

3. On the delete event, we check if the `client.Object` in the `ObjectTransaction` is "expired". If not expired, we upsert the object rather than deleting it.

4. We run a separate `cron`-style `go` routine to cleanup expired objects, based on the `RetentionPolicy` of the object. Runs every hour.

### Indexing

To enable the search features of query service, each object will be indexed so that searching for strings within fields should work.

We will store the full JSON of the object in an `unstructured` field in the data store, so it can be retrieved and visualized later.

```golang
type Object struct {
	ID                  string          `gorm:"primaryKey;autoIncrement:false"`
    // ...
	KubernetesDeletedAt time.Time       `json:"kubernetesDeletedAt"`
	Unstructured        json.RawMessage `json:"unstructured" gorm:"type:blob"`
}
```

We then add this `unstructured` field to the index:

```golang

func (i *bleveIndexer) Add(ctx context.Context, objects []models.Object) error {
    // ...
	if obj.Unstructured != nil {
        var data interface{}

        if err := json.Unmarshal(obj.Unstructured, &data); err != nil {
            return fmt.Errorf("failed to unmarshal object: %w", err)
        }

        batch.Index(obj.GetID(), data)
    }
}
```

This should allow for a `terms` search against the body of the document.

### Retaining specific objects

In the case of events, we probably do not want to retain all events, as many different components will emit events that we may not care about. We will need to specify which objects should be retained by adding a `FitlerFunc` to the `ObjectKind`:

```golang
// FilterFunc can be used to only retain relevant objects.
// For example, we may want to keep Events, but only Events from a particular source.
type FilterFunc func(obj client.Object) bool
```

Here is an example that retains only events from the `source-controller`:

```golang
SourceControllerEventObjectKind := ObjectKind{
    Gvk: corev1.SchemeGroupVersion.WithKind("Event"),
    NewClientObjectFunc: func() client.Object {
        return &corev1.Event{}
    },
    AddToSchemeFunc: corev1.AddToScheme,
    FilterFunc: func(obj client.Object) bool {
        e, ok := obj.(*corev1.Event)
        if !ok {
            return false
        }

        return e.Source.Component == "source-controller"
    },
    RetentionPolicy: RetentionPolicy(24 * time.Hour),
}
```

### Visualizing Arbitrary Objects

Once we have the objects collected, we will need to visualize them in the UI. The simplest way to do this is to show the YAML in the UI and allow for other object-specific UIs to be created in the future.
