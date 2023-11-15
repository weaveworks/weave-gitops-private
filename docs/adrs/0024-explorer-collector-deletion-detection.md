# 24. Explorer Indexer Labels Mapping

Date: 2023-11-15

## Status

Accepted

## Context

Explorer supports querying by labels as they are indexed as part of the object document https://github.com/weaveworks/weave-gitops-enterprise/pull/3573 

For example, 

Given the following template 
```
---
apiVersion: templates.weave.works/v1alpha2
kind: GitOpsTemplate
metadata:
  name: create-gitopsset
  namespace: default
  labels:
    weave.works/template-type: application
spec:
  description: Create an application
  resourcetemplates:
```

You could filter by label in explorer api via Which allows to find the data.  
```
curl 'https://gitops.internal-dev.wego-gke.weave.works/v1/query' \
    ...
  --data-raw '{"terms":"","filters":["labels.weave.works/template-type:application"],"limit":25,"offset":0,"orderBy":"name","descending":false}' \
  --compressed
```

However, current filter by labels relies in using the indexed field id as shown here:  

![filters-label.png](images%2F0024%2Ffilters-label.png)

This is okey when we want dont want to abstract the user from the lower level detail where templateType is just a kubernetes label. 

Given that labels are ways to add attributes to resources meaningful to the users https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/

Applications can use them for representing some business logic as templates does it with `TemplateType` 

![templates-templateType.png](images%2F0024%2Ftemplates-templateType.png)

Therefore, we want to ensure we have a mechanism to map generic to specific resource fields. 

This ADR looks into it and will use template type as driving example.

## Decision

### Achieve Facets Filter `TemplateType`

  



[Tracking issue](https://github.com/weaveworks/weave-gitops-enterprise/issues/2733)

## Consequences

- Tangerine team aligns and knows what should be implemented to fix the issue with RBAC object deletion not propagated to the Explorer UI.
- A user is able to view only those resources in the Explorer UI access to which is granted to them by the RBAC policies.
