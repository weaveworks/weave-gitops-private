# 26. require no maintenance to keep bootstrapping cli up to date

Date: 2023-12-13

## Status

Provisional

## Context

Currently, CLI bootstrapping creates and manages WGE values [here](https://github.com/weaveworks/weave-gitops-enterprise/blob/d27d52cf1053d194a40e7652a570d810db552613/pkg/bootstrap/steps/install_wge.go#L49-L124). This means any update / breaking change happens to WGE values
will lead to degraded bootstrapping process for users and maintaining it will require extra cost. Values should be kept up to date accordingly when they change in the WGE. 

## Decision

Fetching the values file from the corresponding version

example response for fetching the chart from [wge charts url](https://charts.dev.wkp.weave.works/releases/charts-v3)

```yaml
apiVersion: v1
entries:
  mccp:
  - apiVersion: v2
    appVersion: 1.16.0
    created: "2023-12-11T13:29:39.19014457Z"
    dependencies:
    - condition: cluster-controller.enabled
      name: cluster-controller
      repository: file://../cluster-controller
      version: 1.0.0
    - condition: templates-controller.enabled
      name: templates-controller
      repository: file://../templates-controller
      version: 0.3.0
   .
   .
   .
   .
    description: A Helm chart for Kubernetes
    digest: 8d7bab57fd4a1e87112ff950c3b9f65d26df968006d7968af3d5abec843faa79
    name: mccp
    type: application
    urls:
    - https://s3.us-east-1.amazonaws.com/weaveworks-wkp/releases/charts-v3/mccp-0.38.1.tgz
    version: 0.38.1
```

Example url for `v0.38.1` version: `https://s3.us-east-1.amazonaws.com/weaveworks-wkp/releases/charts-v3/mccp-0.38.1.tgz`

By downloading and uncompressing this file you will have the values file corresponding to the downloaded version

Example for `v0.38.1` `mccp/values.yaml`

```yaml
# Default values for mccp.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

images:
  clustersService: docker.io/weaveworks/weave-gitops-enterprise-clusters-service:v0.38.1
  uiServer: docker.io/weaveworks/weave-gitops-enterprise-ui-server:v0.38.1
.
.
.
.
.
.
```

After that, This values file will be converted to `map[string]interface{}` then update the specific values from installation like `oidc` values.

## Consequences

### Pros

- Values will always be up to date

### Cons

- Lost the structured values files
- Extra overhead for downloading / uncompressing the chart file