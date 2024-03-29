# RFC-0004 Fluent-Bit Log Forwarding in GitOps Run

**Status:** implementable

**Creation date:** 2022-12-30

**Last update:** 2023-01-11

## Summary

This RFC proposes the integration of Fluent-Bit into GitOps Run as a log forwarder to collect logs from all pods in a VCluster. Fluent-Bit is written in C/C++ and is lightweight compared to FluentD, which is written in Ruby. It will be installed using Helm and configured to read logs from all containers in the /var/log/containers/ directory, apply the kubernetes filter to merge and exclude relevant log lines, and output the logs to the built-in S3-compatible bucket (the dev-bucket server). An API will also be created to allow users to retrieve logs by pod name and namespace. The storage type and log retention policy for the S3-compatible bucket will be considered, and appropriate documentation will be created for other users and maintainers.

## Motivation

The integration of Fluent-Bit into GitOps Run will provide users with the ability to collect logs from all pods in a VCluster and store them in the built-in S3-compatible bucket (the dev-bucket server) for debugging and troubleshooting purposes. This can be accessed through the GitOps Run UI using the proposed log API. The use of Fluent-Bit allows for a lightweight and efficient solution for log collection and forwarding.

## Goals

- Install and configure Fluent-Bit to collect logs from all pods in the VCluster.
- Set up the built-in S3-compatible bucket (the dev-bucket server) to store the collected logs & configure the bucket credentials for Fluent-Bit to allow it to access the bucket.
- Consider the storage type (in-memory vs disk-based) and log retention policy (currently there is no retention policy in place) for the S3-compatible bucket.
- Write an API that allows users to retrieve logs by pod name and namespace.
- Document the system and API for other users and maintainers.

## Non-Goals

- The integration of FluentD as a log forwarder is not within the scope of this RFC.
- Automatic deletion of logs based on the time-to-live (TTL) of the S3 bucket is not within the scope of this RFC.

## Proposal

The proposed system will collect logs from all pods in a VCluster-based session and store them in the built-in S3-compatible bucket (the dev-bucket server) for easy access and retrieval. 
We will also create an API that allows users to retrieve logs by pod name and namespace, making it even easier to troubleshoot and debug issues in the VCluster-based session.

We have already completed a spike to create the necessary HelmRepository and HelmRelease objects for this integration, 
and we will now parameterize and convert these objects into GitOps Run commands for easy installation and management.

The YAML from the spike's outcome is presented here:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
metadata:
  name: fluent
  namespace: flux-system
spec:
  interval: 1h0s
  url: https://fluent.github.io/helm-charts
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: fluent-bit
  namespace: flux-system
spec:
  chart:
    spec:
      chart: fluent-bit
      sourceRef:
        kind: HelmRepository
        name: fluent
      version: '*'
  interval: 1h0s
  releaseName: fluent-bit
  targetNamespace: flux-system
  install:
    crds: Create
  upgrade:
    crds: CreateReplace
  values:
    env:
    - name: AWS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: run-dev-bucket-credentials # share with bucket source
          key: accesskey
    - name: AWS_SECRET_ACCESS_KEY
      valueFrom:
        secretKeyRef:
          name: run-dev-bucket-credentials # share with bucket source
          key: secretkey
    config:
      inputs: |
        [INPUT]
            Name tail
            Path /var/log/containers/*.log
            multiline.parser docker, cri
            Tag kube.*
            Mem_Buf_Limit 5MB
            Skip_Long_Lines Off
      filters: |
        [FILTER]
            Name kubernetes
            Match kube.*
            Merge_Log On
            Keep_Log Off
            K8S-Logging.Parser On
            K8S-Logging.Exclude On
        [FILTER]
            Name    grep
            Match   *
            Exclude $kubernetes['namespace_name'] (gitops-run|kube-system)
        [FILTER]
            Name    grep
            Match   *
            Exclude $kubernetes['pod_name'] ^fluent\-bit
      outputs: |
        [OUTPUT]
            Name s3
            Match kube.*
            bucket pod-logs
            endpoint http://run-dev-bucket.gitops-run.svc:38011 # this port value needs parameterization
            tls Off
            tls.verify Off
            use_put_object true
            preserve_data_ordering true
            static_file_path true
            total_file_size 1M
            upload_timeout 15s
            s3_key_format /fluent-bit-logs/$TAG[4].%Y%m%d%H%M%S
```

## Alternatives

One alternative to using Fluent-Bit for log collection and forwarding in a VCluster is to use FluentD. FluentD is also a log forwarder, but it is written in Ruby and is generally considered to be more resource-intensive than Fluent-Bit. However, FluentD has a wider array of input and output plugins, which may make it a better choice for certain use cases.

Another alternative is to use a Kubernetes logging agent such as FileBeat or Logstash which both have Kubernetes integration, similar to Fluent-Bit.

Another alternative would be using a third-party log aggregation platform like Elasticsearch, Logstash and Kibana (ELK) stack or Splunk which can be installed and configured in the VCluster to collect, analyze and visualize logs. This method is far more complex to set up and maintain, but it can provide more advanced features such as log querying, indexing, and alerting.

## Rationale

The integration of Fluent-Bit into GitOps Run as a log forwarder provides a lightweight and efficient solution for log collection and forwarding. It allows users to easily access logs for debugging and troubleshooting purposes through the GitOps Run UI. The proposed configuration and API will meet the goals of this RFC while keeping the implementation as simple and flexible as possible.

## Compatibility
The integration of Fluent-Bit into GitOps Run should not have any compatibility issues.

## Implementation

The implementation of this feature will involve installing and configuring Fluent-Bit as part of the GitOps Run command, configuring credentials for Fluent-Bit to access the dev-bucket server, considering the storage type (in-memory or disk-based)and log retention policy (currently there is no retention policy in place) for the dev-bucket, writing an API for log retrieval, and creating documentation. These tasks should be assigned to a development team, with appropriate testing and documentation being performed at each step.

## Open issues (if applicable)
- Further discussion is needed on the storage type and log retention policy for the dev-bucket.
- The API for log retrieval and its integration into the GitOps Run UI need to be designed and implemented.

## User Stories

As a user, I want to be able to install Fluent-Bit including the credentials using Flux HelmRelease object via the GitOps Run command, so that I can use it as a log forwarder in GitOps Run.

As a user, I want to be able to configure Fluent-Bit to collect logs from all pods in VCluster-based sessions, so that I can use them for debugging and troubleshooting purposes.

As a user, I want to be able to retrieve logs by pod name and namespace using an API so that I can use it for debugging and troubleshooting purposes in the GitOps Run UI.

As a user, I want to have documentation available for the system and API so that I can understand how to use and maintain it.

As a user, I want to be able to consider the storage type and log retention policy for the dev-bucket so that I can choose the appropriate options for my use case.
