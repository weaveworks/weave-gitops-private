# UI Backend integration spike 
It aims to document the spike done in the context of cd pipelines about integrating pipelines ui and backend. 

## Glossary 

- Pipeline: define application deployment across environment 
- Pipeline Execution: an instance of a pipeline being executed so application being deployed through environments.

## Problem statement 
Two main user stories could be considered within this integration 

1. As gitops user I want to discover pipelines or list pipelines. 
2. As gitops user I want to discover pipeline executions or list pipeline execution.
3. As gitops user I want to follow a pipeline execution or pipeline execution details.

This document focuses on entity pipeline execution so 2) and 3) while 1) should be addressed in the context of [pipeline 
definition spike](https://github.com/weaveworks/weave-gitops-enterprise/issues/1076)

## Assumptions and Dependencies 

This includes the context assumptions or dependencies we need to make in order to complete the picture

- A [pipeline definition](https://github.com/weaveworks/weave-gitops-enterprise/issues/1076) exists from a previous spike
- A `pipeline execution` is the entity/contract between 
  - this spike reads the execution entity  
  - https://github.com/weaveworks/weave-gitops-enterprise/issues/1084 writes the execution entity
  - we could resolve `pipelines` from `pipeline executions`

## Alternatives

In order the UI to follow a pipeline execution, the following three alternatives has been identified 

1. To create an api endpoint that serves `pipeline execution` resources (CRD). 
2. To consume flux/deployment events and do the orchestration logic within the UI.
3. To gather the pipeline execution logic within a configmap. UI to consume these configmaps.  

//TODO diagrams https://github.com/mermaid-js/mermaid#readme

### To create an api endpoint that serves `pipeline execution` resources (CRD).

![CRD Alternative](imgs/ui-integration-alternative-1.png)

**Pro** 
- Single document to represent the execution of a pipeline 
- CRD so out of the box CRD benefits like versioning or validation //TODO: review  

**Cons**
- TBA

### To consume flux/deployment events and do the orchestration logic within the UI.

![UI Alternative](imgs/ui-integration-alternative-2.png)

**Pro**
- TBA

**Cons**
- Doing the orchestration in the UI translates some business logic responsibility to the UI which is an anti-pattern as 
  - exposing our business logic means to potentially expose our competitive advantage
  - limits extensibility as we cannot integrate with other experience layers or via duplicating effort 


### To gather the pipeline execution logic within a configmap. UI to consume these configmaps.

![ConfigMap Alternative](imgs/ui-integration-alternative-3.png)

**Pro**
- Configmaps are first-class kube citizens so reduces maintenance solution effort.  
- No controller needed

**Cons**
- Validation not out of the box
- They are namespaced so might impose constraints on the access patterns    


## Alternatives evaluation summary  

- Pipeline Execution 
- UI Orchestration: discarded as not viable solution. 
- Configmap
- 



## More info needed

- Define roles and responsibilities for execution entities by role



## References

- [Miro Board](https://miro.com/app/board/uXjVOoWHIfg=/?share_link_id=613790573756)
