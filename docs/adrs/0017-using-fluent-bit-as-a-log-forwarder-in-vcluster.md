# 17. using fluent-bit as a log forwarder for vcluster pod logs

## Status

Proposed

## Context:

- We currently use vcluster as our GitOps Run session implementation.
- GitOps Run sessions are ephemeral environments.
- We already have our own S3 bucket server implementation inside vcluster, which we use to store session logs.
- There is a need to collect and store logs from all pods in a vcluster for debugging and troubleshooting purposes.

## Decision

- We will use Fluent-Bit as a log forwarder to collect logs from all pods in the VCluster. Fluent-Bit is a lightweight log forwarder written in C/C++, making it suitable for our needs.
- We will use Flux HelmRelease to install Fluent-Bit and configure it to read logs from the /var/log/containers/ directory and apply the Kubernetes filter.
- We will set up an S3 bucket inside the vcluster to store the collected logs.
- We will configure AWS credentials for Fluent-Bit to allow it to access the S3 bucket.
- We will consider the storage type (disk or memory) and log retention policy for the S3 bucket. For now, we will use the in-memory setting as is.
- We will write an API that allows users to retrieve logs by pod name and namespace.
- We will document the system and API for other users and maintainers.

## Reasoning

- Fluent-Bit is a suitable log forwarder for our needs as it is lightweight and written in C/C++.
- Using Flux HelmRelease to install Fluent-Bit is conformed to what we did in GitOps Run.
- Storing the collected logs in an S3 bucket inside the vcluster will make them easily accessible for debugging and troubleshooting purposes.
- Considering the storage type and log retention policy for the S3 bucket will ensure that we are using an appropriate solution for long-term storage of the logs.
- An API that allows users to retrieve logs by pod name and namespace is required for the management cluster to access those logs.
- Documenting the system and API will ensure that other users and maintainers are aware of how it works and how to use it.

## Consequences

- Using Fluent-Bit as a log forwarder will allow us to collect and store logs from all pods in the vcluster.
- Storing the collected logs in an S3 bucket inside the VCluster will make them accessible from the management cluster.
- An API that allows users to retrieve logs by pod name and namespace will be required to implement.
- Documenting the system and API will ensure that other users and maintainers are aware of how it works and how to use it.
