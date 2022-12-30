RFC-0004 Fluent-Bit Log Forwarding in Weave GitOps
Status: implementable

Creation date: 2022-12-30

Last update: 2022-12-30

## Summary

This RFC proposes the integration of Fluent-Bit into Weave GitOps as a log forwarder to collect logs from all pods in a VCluster. Fluent-Bit is written in C/C++ and is lightweight compared to FluentD, which is written in Ruby. It will be installed using Helm and configured to read logs from all containers in the /var/log/containers/ directory, apply the kubernetes filter to merge and exclude relevant log lines, and output the logs to an S3 bucket. An API will also be created to allow users to retrieve logs by pod name and namespace. The storage type and log retention policy for the S3 bucket will be considered, and appropriate documentation will be created for other users and maintainers.

## Motivation

The integration of Fluent-Bit into Weave GitOps will provide users with the ability to collect logs from all pods in a VCluster and store them in an S3 bucket for debugging and troubleshooting purposes. This can be accessed through the GitOps Run UI using the proposed log API. The use of Fluent-Bit allows for a lightweight and efficient solution for log collection and forwarding.

## Goals

- Install and configure Fluent-Bit to collect logs from all pods in the VCluster.
- Set up an S3 bucket to store the collected logs & configure AWS credentials for Fluent-Bit to allow it to access the S3 bucket.
- Consider the storage type and log retention policy for the S3 bucket.
- Write an API that allows users to retrieve logs by pod name and namespace.
- Document the system and API for other users and maintainers.

## Non-Goals
- The integration of FluentD as a log forwarder is not within the scope of this RFC.
- Automatic deletion of logs based on the time-to-live (TTL) of the S3 bucket is not within the scope of this RFC.

## Proposal

To integrate Fluent-Bit into Weave GitOps, the following steps will be taken:

1. Install Fluent-Bit using Helm and add the Fluent repository:

    ```
    helm repo add \
      fluent \
      https://fluent.github.io/helm-charts
    ```

2. Install Fluent-Bit as a Helm release:

    ```
    helm upgrade --install \
      fluent-bit \
      fluent/fluent-bit
    ```

3. Configure Fluent-Bit to collect logs from all pods in the VCluster using the following configuration:

    ```
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
    
    outputs: |
    [OUTPUT]
      Name s3
      Match kube.*
      bucket pod-logs
      endpoint https://host.docker.internal:9000
      tls_verify false
    ```

4. Configure AWS credentials for Fluent-Bit to allow it to access the S3 bucket. This can be done by following the instructions in the Fluent-Bit documentation:
https://github.com/fluent/fluent-bit-docs/blob/master/administration/aws-credentials.md

5. Consider the storage type and log retention policy for the S3 bucket. The storage type can be either disk or memory, with disk being more durable but potentially slower to access and memory being faster but potentially less suitable for long-term storage. The log retention policy can be set using a time-to-live (TTL) value to automatically delete logs after a certain period of time.

6. Write an API that allows users to retrieve logs by pod name and namespace. This API can be served as an additional feature in the GitOps Run UI for debugging and troubleshooting purposes.

7. Document the system and API for other users and maintainers. This documentation should include instructions on how to install and configure Fluent-Bit, how to set up the S3 bucket and configure AWS credentials, and how to use the log API.

A complete example of a HelmRelease of steps 1-3 is presented here:

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
            endpoint http://run-dev-bucket.gitops-run.svc:38011
            tls Off
            tls.verify Off
            use_put_object true
            preserve_data_ordering true
            static_file_path true
            total_file_size 1M
            upload_timeout 15s
            s3_key_format /fluent-bit-logs/$TAG[4].%Y%m%d%H%M%S
```

## Rationale

The integration of Fluent-Bit into Weave GitOps as a log forwarder provides a lightweight and efficient solution for log collection and forwarding. It allows users to easily access logs for debugging and troubleshooting purposes through the GitOps Run UI. The proposed configuration and API will meet the goals of this RFC while keeping the implementation as simple and flexible as possible.

## Compatibility
The integration of Fluent-Bit into Weave GitOps should not have any compatibility issues.

## Implementation

The implementation of this feature will involve installing and configuring Fluent-Bit, setting up an S3 bucket and configuring AWS credentials, considering the storage type and log retention policy for the S3 bucket, writing an API for log retrieval, and creating documentation. These tasks should be assigned to a development team, with appropriate testing and documentation being performed at each step.

## Open issues (if applicable)
- Further discussion is needed on the storage type and log retention policy for the S3 bucket.
- The API for log retrieval and its integration into the GitOps Run UI need to be designed and implemented.

## User Stories

As a user, I want to be able to install Fluent-Bit using Flux HelmRelease object so that I can use it as a log forwarder in GitOps Run.

As a user, I want to be able to configure Fluent-Bit to collect logs from all pods in the VCluster so that I can use it for debugging and troubleshooting purposes.

As a user, I want to be able to set up an S3 bucket to store the collected logs so that I can access them later.

As a user, I want to be able to configure AWS credentials for Fluent-Bit so that it can access the S3 bucket.

As a user, I want to be able to retrieve logs by pod name and namespace using an API so that I can use it for debugging and troubleshooting purposes in the GitOps Run UI.

As a user, I want to have documentation available for the system and API so that I can understand how to use and maintain it.

As a user, I want to be able to consider the storage type and log retention policy for the S3 bucket so that I can choose the appropriate options for my use case.
