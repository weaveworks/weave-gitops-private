# UI Backend integration spike 
It aims to document the spike done in the context of cd pipelines about integrating pipelines ui and backend.

## Glossary 

- Pipeline: define application deployment across environment 
- Pipeline Status: an instance of a pipeline being executed so application being deployed through environments.
- Pipeline History: a list of pipeline 

## Problem statement 
Two main user stories to be considered in this spike for this version 0.1 is 

- As gitops user with an application and a pipeline defined for that application. I want to be able to follow how an application 
change gets delivered to different environments.

This spike works out solutions for enabling the user experience to provide that information to the user. 

## Assumptions and Dependencies and out of scope

**Notes**
- The solutions in this document are not meant to be prescriptive but the building blocks for the solution. The aim
of the spike is to discover the solution but the concrete design of it should be done over the one agreed by the team in their proper
stories.

**Out of the scope**
- Any pipeline capability which is not making visible the delivery of the last change to an app. For example, pipeline history.

**Assumptions**
This includes the context assumptions or dependencies we need to make in order to complete the picture

- A [pipeline definition](https://github.com/weaveworks/weave-gitops-enterprise/issues/1076) exists from a previous spike. 
- A `pipeline execution` is the entity/contract between 
  - this spike reads the execution entity and 
  - https://github.com/weaveworks/weave-gitops-enterprise/issues/1083 that might create it
  - https://github.com/weaveworks/weave-gitops-enterprise/issues/1084 that might update it
  - we could resolve `pipelines` from `pipeline executions` 

Alternatives used are shown below 

### Pipelines by label approach

https://github.com/weaveworks/weave-gitops-private/pull/54/files

- Pipeline definition as `HelmRelease` with labels `pipelines.wego.weave.works/name` and `pipelines.wego.weave.works/stage`
- Pipeline status as  `HelmRelease` status from flux
```sh
$$ kubectl get hr -A -o jsonpath='{range .items[*]}{.metadata.name}/{.metadata.labels.pipelines\.weave\.works/stage}/{.status.lastAppliedRevision}: {@.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' -l pipelines.weave.works/name=podinfo
podinfo/0/6.1.6: True
podinfo/1/6.1.0: True
```



does not have a consolidated pipeline state view, to be created in the pipeline api integration, shoulds too haeav
### Pipelines by CRD approach

From https://github.com/rparmer/pipelines
As simplification for this spike we are just considering [full crd approach](https://github.com/rparmer/pipelines#full-crd-approach)

- Pipeline definition as `HelmRelease` with labels `pipelines.wego.weave.works/name` and `pipelines.wego.weave.works/stage`
```yaml
apiVersion: wego.weave.works/v1alpha2
kind: Pipeline
metadata:
  name: example-pipeline
  namespace: flux-system
spec:
  stages:
    - name: dev
      namespace: dev
      order: 1
      releaseRefs: # list of `Kustomization` or `HelmRelease` objects. They MUST be in the defined stage namespace
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: dev # name of kustomization object (doesn't have to match stage name)
          kind: Kustomization
    - name: staging
      namespace: staging
      order: 2
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: staging
          kind: Kustomization
    - name: prod
      namespace: prod
      order: 3
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: prod
          kind: Kustomization
```
- Pipeline status not identified. Assuming a similar approach to `labels` alternative where we could check the status of the execution 

```yaml
apiVersion: wego.weave.works/v1alpha2
kind: Pipeline
metadata:
  name: example-pipeline
  namespace: flux-system
spec:
  stages:
    - name: dev
      namespace: dev
      order: 1
      releaseRefs: # list of `Kustomization` or `HelmRelease` objects. They MUST be in the defined stage namespace
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: dev # name of kustomization object (doesn't have to match stage name)
          kind: Kustomization
    - name: staging
      namespace: staging
      order: 2
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: staging
          kind: Kustomization
    - name: prod
      namespace: prod
      order: 3
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: prod
          kind: Kustomization
status:
  conditions:
    - lastTransitionTime: "2022-04-07T12:34:58Z"
      message: 'Environment Completed: 3 (Failed: 0, Canceled 0), Skipped: 0'
      reason: Succeeded
      status: "True"
      type: Succeeded
  environments:
    - name: dev
      order: 0
      status:
        # status field info with for example
        type: Succeeded
        time: now - 2
    - name: staging
      order: 1
      statusInfo:
        # status field info with for example
        type: Succeeded
        time: now - 1
    - name: prod
      order: 1
      statusInfo:
        # status field info with for example
        type: Succeeded
        time: now
```

## Alternatives

In order the UI to follow a pipeline execution, the following three alternatives has been identified 

1. To create an api endpoint that serves `pipeline` from labels.
2. To create an api endpoint that serves `pipeline` from CRD.
3. To create an api endpoint that serves `pipeline execution` from CRD  
4. To consume flux/deployment events and do the orchestration logic within the UI.
5. To gather the pipeline execution logic within a configmap. UI to consume these configmaps.  


### To create an api endpoint that serves `pipeline` from labels.

```json
 "/v1/pipelines/{name}": {
      "get": {
        "operationId": "Pipelines_GetPipeline",
        "responses": {
          "200": {
            "description": "A successful response.",
            "schema": {
              "$ref": "#/definitions/GetPipelinenResponse"
            }
          },
        },
        "parameters": [
        // search filters
        ],
      }
    },
``` 

```protobuf
message GetPipelineResponse {
  Pipeline pipeline;
}

//discover pipeline by labels pipelines.wego.weave.works/name
message Pipeline {
  string name; 
  string application;
  PipelineEnvironmentStatus environments;
}

//discover pipeline stages by labels pipelines.wego.weave.works/stage
//this information comes from HelmRelease status 
message PipelineEnvironmentStatus {
  string name;
  string status;
  string version;
  string message;
  // other options
}
```

**Pro**
- It would address our scenario 

**Cons**
- Needed a service layer to calculate a pipeline state view. 
- To have this responsibility within the api / integration layer sounds expensive 
  if calculated at each request or complex in case that requires some caching mechanism.  


### To create an api endpoint that serves `pipeline` from CRD.

Same as previous alternative but instead of constructing an entity, we just return the pipeline entity that already 
exists in the API 

```json
 "/v1/pipelines/{name}": {
      "get": {
        "operationId": "Pipelines_GetPipeline",
        "responses": {
          "200": {
            "description": "A successful response.",
            "schema": {
              "$ref": "#/definitions/GetPipelinenResponse"
            }
          },
        },
        "parameters": [
        // search filters
        ],
      }
    },
``` 

```protobuf
message GetPipelineResponse {
  Pipeline pipeline;
}
```

```yaml
apiVersion: wego.weave.works/v1alpha2
kind: Pipeline
metadata:
  name: example-pipeline
  namespace: flux-system
spec:
  stages:
    - name: dev
      namespace: dev
      order: 1
      releaseRefs: # list of `Kustomization` or `HelmRelease` objects. They MUST be in the defined stage namespace
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: dev # name of kustomization object (doesn't have to match stage name)
          kind: Kustomization
    - name: staging
      namespace: staging
      order: 2
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: staging
          kind: Kustomization
    - name: prod
      namespace: prod
      order: 3
      releaseRefs:
        - name: podinfo-pipeline-helm
          kind: HelmRelease
        - name: prod
          kind: Kustomization
status:
  conditions:
    - lastTransitionTime: "2022-04-07T12:34:58Z"
      message: 'Environment Completed: 3 (Failed: 0, Canceled 0), Skipped: 0'
      reason: Succeeded
      status: "True"
      type: Succeeded
  environments:
    - name: dev
      order: 0
      status:
        # status field info with for example
        type: Succeeded
        time: now - 2
    - name: staging
      order: 1
      statusInfo:
        # status field info with for example
        type: Succeeded
        time: now - 1
    - name: prod
      order: 1
      statusInfo:
        # status field info with for example
        type: Succeeded
        time: now
```

**Pro**
- It would address our need.
- Integration layer does not need to create a pipeline view.

**Cons**
- Not defined who would be updating the status in a pipeline resource. 


### To create an api endpoint that serves `pipeline execution` resources (CRD).

![CRD Alternative](imgs/ui-integration-alternative-1.png)

the api endpoint could look like

```json
 "/v1/pipelines/{name}/executions": {
      "get": {
        "operationId": "Pipelines_GetPipelineExecutions",
        "responses": {
          "200": {
            "description": "A successful response.",
            "schema": {
              "$ref": "#/definitions/GetPipelineExecutionResponse"
            }
          },
        },
        "parameters": [
        // search filters
        ],
      }
    },
``` 

```protobuf
message GetPipelineExecutionResponse {
  ...
  PipelineExecution pipelineExecution;
  ...
}
```

```yaml
apiVersion: gitops.weave.works/v1alpha1
kind: PipelineExecution
metadata:
  name: my-hello-pipeline-execution-abc123
  ...
spec:
  params:
  - name: HELLO
    value: Hello World!
  trigger:
    # info about the trigger
  pipelineRef:
    name: my-hello-pipeline
    namespace: hello-world
status:
  conditions:
  - lastTransitionTime: "2022-04-07T12:34:58Z"
    message: 'Environment Completed: 3 (Failed: 0, Canceled 0), Skipped: 0'
    reason: Succeeded
    status: "True"
    type: Succeeded
  environments:
  - name: dev 
    order: 0 
    status:
      # status field info with for example
      type: Succeeded
      time: now - 2 
  - name: test
    order: 1
    statusInfo: 
      # status field info with for example
      type: Succeeded
      time: now - 1 
```

**Pro** 
- Single document to represent the execution of a pipeline 
- CRD so out of the box CRD benefits like versioning or validation 
//TODO: review  

**Cons**
- Given there is already a pipeline resource directly or indirectly been referenced, and it supports the use story we are 
aiming at this iteration. to add a new entity it would only add complexity and overhead. 

This concept is being for example explored within 

- [Tekton](https://tekton.dev/docs/pipelines/pipelineruns/#overview)


### To consume flux/deployment events and do the orchestration logic within the UI.

![UI Alternative](imgs/ui-integration-alternative-2.png)

**Pro**
- TBA

**Cons**
- Doing the orchestration in the UI translates some business logic responsibility to the UI which is an anti-pattern as 
  - exposing our business logic means to potentially expose our competitive advantage
  - limits extensibility as we cannot integrate with other experience layers or via duplicating effort 

This solution is not viable so no longer explored. 

### To gather the pipeline execution logic within a configmap. UI to consume these configmaps.

![ConfigMap Alternative](imgs/ui-integration-alternative-3.png)

the api endpoint could look like

```json
 "/v1/pipelines/{name}/executions": {
      "get": {
        "operationId": "Pipelines_GetPipelineExecutions",
        "responses": {
          "200": {
            "description": "A successful response.",
            "schema": {
              "$ref": "#/definitions/GetPipelineExecutionResponse"
            }
          },
        },
        "parameters": [
        // search filters
        ],
      }
    },
``` 

```protobuf
message GetPipelineExecutionResponse {
  ...
  ConfigMap pipelineExecution;
  ...
}
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-hello-world-pipeline-execution
data:
  #metadata could be also annotations or similar
  #pipeline ref properties
  pipeline_name: "my-hello-pipeline"
  pipeline_namespace: "hello-world"
  #status examples
  environment_0_name: "dev"
  environment_0_status: "succeded"
  environment_1_name: "test"
  environment_1_status: "succeded"
  
```

**Pro**
- Configmaps are first-class kube citizens so reduces maintenance solution effort.  
- No controller needed

**Cons**
- Given there is already a pipeline resource directly or indirectly been referenced, and it supports the use story we are
  aiming at this iteration. to add a new entity it would only add complexity and overhead.
- Validation not out of the box
- They are namespaced so might impose constraints on the access patterns    

## Recommendation (with limitations)

It is recommended to align to the pipeline definition so considering as potential alternatives

- Pipelines based on labels 
- Pipelines based on CRDs

So solutions not based on existing pipeline definitions are not recommended. 

From these two alternatives, we find the same limitation, not answered how a pipeline state view is created in the backend.
This is a dependency on other spikes not yet completed
- https://github.com/weaveworks/weave-gitops-enterprise/issues/1083 that might create it
- https://github.com/weaveworks/weave-gitops-enterprise/issues/1084 that might update it

Beyond that limitation, to create a view out of the labels would be an O(n) or O(n log n) while out of CRD would be O(1)

## Path
- Resolve limitations with team on the pipeline state creation.

## Metadata
- Status: Draft in progress. Depends on previous spikes.

## References

- [Miro Board](https://miro.com/app/board/uXjVOoWHIfg=/?share_link_id=613790573756)
