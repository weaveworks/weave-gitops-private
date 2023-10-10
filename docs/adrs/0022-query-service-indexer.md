# 22. Query Service Indexer

Date: 2023-08-18

## Status

Draft

## Context

Our solution for cross-cluster querying has evolved to support some powerful querying patterns (complex AND/OR logic, full-text search), but may be deficient for the next level of capabilities that our (internal) users are asking for.

At present, we can do fairly complex query logic with **normalized fields**:

```golang

// Given these objects
objects := []models.Object{
    {
        Cluster:    "management",
        Name:       "podinfo-a",
        Namespace:  "namespace-a",
        Kind:       "HelmChart",
        APIGroup:   "apps",
        APIVersion: "v1",
    },
    {
        Cluster:    "management",
        Name:       "podinfo-b",
        Namespace:  "namespace-a",
        Kind:       "HelmRepository",
        APIGroup:   "apps",
        APIVersion: "v1",
    },
    {
        Cluster:    "management",
        Name:       "podinfo-d",
        Namespace:  "namespace-b",
        Kind:       "HelmRepository",
        APIGroup:   "apps",
        APIVersion: "v1",
    },
}


qs := NewQueryService(...)


q := &query{filters: []string{
    // Regex-style query where we can add the OR logic within a field.
    "kind:/(HelmChart|HelmRepository)/",
    // Top-level fields are AND'd together.
    "namespace:namespace-a",
}}


result := qs.RunQuery(q)
// result will have "podinfo-a", "podinfo-b", but not "podinfo-d" since it is not in namespace-a
```

This works for enumerable fields, but there may be cases where we need to query against fields for which we do not know the key/value pairs. For example, if we want to query for labels on an object we run into a couple issues:

- We don't know the fields for a given object's labels before adding them to the indexer
- Each object's labels have their own key/value pairs that are only relevant in the context of one object, or more realistically, one `kind` of object

An example of two normalized objects with different label pairs:

```golang
objects := []models.Object{
    {
        Cluster:    "management",
        Name:       "podinfo-a",
        Namespace:  "namespace-a",
        Kind:       "HelmChart",
        APIGroup:   "apps",
        APIVersion: "v1",
        Labels: map[string]string{
            "weave.works/template": "true",
        }
    },
    {
        Cluster:    "management",
        Name:       "podinfo-b",
        Namespace:  "namespace-a",
        Kind:       "HelmRepository",
        APIGroup:   "apps",
        APIVersion: "v1",
        Labels: map[string]string{
            "other.org.com/somekey": "othervalue",
        }
    },
}
```

Given this data ^^, here is the type of query we would like to support:

```golang
q := &query{
    labels: map[string]string{
        "weave.works/template": "true",
    }
    filters: []string{
        "kind:/(HelmChart|HelmRepository)/",
    },
}
```

The main issue with this query is that [bleve](https://blevesearch.com/), our current indexing/querying solution is not capable of doing this type of query, or if it is, the documentation available does not explain how it can be done.

## Decision

## Consequences
