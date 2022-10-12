### Determine whether a promotion is needed



### Non-functional requirements

As an enterprise feature, we try also to understand the considerations in terms of non-functional requirements to ensure
that no major impediments are found in the future.

#### Security

Promotions have a couple of activities that requires to drill down in terms of security:

1. communication of deployment changes via webhook so over the network.
2. to create pull requests, so write access to gitops configuration repo.

**Security for deployment changes via webhook**

Communications between leaf cluster and management cluster will be protected using HMAC. HMAC shared key
will be used for both authentication and authorization. Application teams will be able to specify the key to use within
the pipeline spec as a global value. Key management will be done by the application team.

Both to simplify user experience for key management and other security configuration will be evolved over time.

An example to visualise this configuration is shown below.

```yaml
  appRef:
    apiVersion: helm.toolkit.fluxcd.io/v2beta1
    kind: HelmRelease
    name: podinfo
    #used for hmac authz - this could change at implementation 
    secretRef: my-hmac-shared-secret 
```

**Security for pull requests**

In order to create a pull request in a configuration repo to action would be mainly required:

1. To clone the configuration git repo via http or ssh.
2. To create a pull request with promoted changes.

Both actions would require a secret to use that ends in a combination of possible scenarios to eventually support.
This document assumes the simplest scenario possible which is having a single token for both
cloning via http and to create a pull request. The token will be present as kubernetes secrets and accessible by pipeline controller.

An example to visualise this configuration is shown below.

```yaml
  promotion:
  - name: promote-via-pr
    type: pull-request
    url: https://github.com/organisation/gitops-configuration-monorepo.git
    branch: main
    secretRef: my-gitops-configuration-monorepo-secret #contains the github token to clone and create PR  
```

#### Scalability

The initial strategy to scale the solution by number of request, would be vertically by using goroutines.

#### Reliability

It will be implemented as part of the business logic of pipeline controller.

#### Monitoring

To leverage existing [kubebuilder metrics](https://book.kubebuilder.io/reference/metrics.html). There will be the need
to enhance default controller metrics with business metrics like `latency of a promotion by application`.