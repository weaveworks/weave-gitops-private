# 25. CLI bootstrapping access step

Date: 2023-11-29

## Status

Accepted

## Context

Timberwolf is currently working in the [cli bootstrapping](https://docs.gitops.weave.works/docs/enterprise/getting-started/install-enterprise-cli/) initiative.
One of the workflow steps is to configure the networking access to the app. Current cli implemented approach supports a couple of specific 
use cases, however, in WGE [helm chart](https://github.com/weaveworks/weave-gitops-enterprise/blob/main/charts/mccp/values.yaml) we have many other configuration options. 

We want to iterate the existing solution to ensure it cover the most of the expected use cases. We have these different alternatives:

1. Build a complete experience through the cli for all the configuration options.
2. Create subcommand to configure ingress after bootstrapping.
3. Build basic experience and leave the user the ability to adapt the values via configuration outside the bootstrapping flow.
4. Build a cli experience where the user can point to configuration files that contains the values to be used. 

### Build a complete experience through the cli for all the configuration options

This would look like as to provide guided paths in the CLI for each potential different configurations. 
An example of the helm chart values for service shows below:
```yaml
service:
  type: ClusterIP
  ports:
    https: 8000
  targetPorts:
    https: 8000
  nodePorts:
    http: ""
    https: ""
    tcp: {}
    udp: {}
  clusterIP: ""
  externalIPs: []
  loadBalancerIP: ""
  loadBalancerSourceRanges: []
  externalTrafficPolicy: ""
  healthCheckNodePort: 0
  annotations: {} 
```

**Drawbacks / Risks:** 
- It could lead to a difficult cli navigation due to the various options that the user might need to go through.
- It is a costly solution to build from the beginning and likely to require multiple iterations to complete.
 
These risks make this alternative not a suitable choice at the current stage of the project.  

### Create subcommand to configure ingress after bootstrapping.
This solution would: 
1. Provision ClusterIp by default 
2. Allows the user to extend ingress via subcommand after bootstrapping.

Something like `gitops bootstrap access <add/remove> --type=ingress --<+ingress-flags>` or `gitops bootstrap access --type=loadbalancer --<+loadbalancer-flags>`

This solution ensures that there is a simple basic experience during bootstrapping and allow the user to configure the 
ingress to its needs. 

**Drawbacks / Risks:**
- A costly solution to build from the beginning and likely to require multiple iterations to complete.
- We would need also to implement the lifecycle for removal of access.

### Build basic experience and leave the user the ability to adapt the values via configuration outside the cli

This solution aims to provide:
1. a basic default solution that works for any user given our assumptions. 
2. the possibility to extend the solution out of the bootstrapping flow to adjust to the specific needs.

The `basic default solution` would be to expose the app via `ClusterIP` which allow accessing the app via port-forward to test 
and verify the solution. This experience would be suitable for day-0 journeys that we currently aim for. 

The `extension mechanism` would be to add as commented in the helm release the service and ingress values that comes by default in 
the helm chart. The user would adjust it out of the bootstrapping flow. 

```yaml 
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: weave-gitops-enterprise
spec:
  releaseName: weave-gitops-enterprise
 ...
  values:
    service:
      type: ClusterIP
      ports:
        https: 8000
      targetPorts:
        https: 8000
      nodePorts:
        http: ""
        https: ""
        tcp: {}
        udp: {}
      clusterIP: ""
      externalIPs: []
      loadBalancerIP: ""
      loadBalancerSourceRanges: []
      externalTrafficPolicy: ""
      healthCheckNodePort: 0
      annotations: {}
```
**Drawbacks / Risks:**

- It requires that platform engineer doing the bootstrap to create the port-forward to the app to test it. Given we expect the user has admin permissions to the clusters,
seems a sensible assumption to have.
- The user needs to edit the helm release out of the bootstrapping flow to get to other configurations.

### Build a cli experience where the user can point to configuration files that contains the values to be used.

Something like this:

`gitops bootstrap --values=values.yaml`

where values file would be the values file for Weave GitOps Enterprise chart

```yaml
# Default values for mccp.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""

images:
  clustersService: docker.io/weaveworks/weave-gitops-enterprise-clusters-service:v0.0.2
  uiServer: docker.io/weaveworks/weave-gitops-enterprise-ui-server:v0.0.2

...

```
**Drawbacks / Risks:**
- The project currently does not support configuration via file.
- Where the user gets the values file in the first place.
- Which values to include in the first place:
  - if we include all values -> a user in day-0 would require to take many decisions or have a deep understanding of the product 
  - if we just use ingress and service -> it creates some sort of inconsistency with other steps. For example, the user could 
  think, I could configure ingress via configuration file, why not also other steps like OIDC

## Decision

Given the previous context we think that best approach would be to iterate towards the third option  
`Build basic experience and leave the user the ability to adapt the values via configuration outside the cli`

As it allows us: 
- A simple bootstrapping flow for the user. 
- A cheap to implement extension mechanism.
- Under the balanced assumptions that the platform engineer doing bootstrapping have knowledge kubernetes.

## Consequences

- We got a clear path to implement the bootstrapping flow.
- We need to reflect it in the documentation how to achieve other scenarios