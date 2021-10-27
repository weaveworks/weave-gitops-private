# 10. Container Labels

Date: 2021-10-27

## Status

Accepted

## Context

We need additional metadata associated with our published container images to provide end-users information about who provided the image, when it was built, and license info.  This information is also helpful for us when troubleshooting a customer environment as it will enable us to rebuild the images to test locally.

## Decision

Add the following labels to all the Weave Gitops Core and Enterprise container images.

<br/>**org.opencontainers.image.created**: Date the image was created e.g., "2021-10-22T12:41:17Z",
<br/>**org.opencontainers.image.description**: Short description e.g., "The Weave GitOps API service"
<br/>**org.opencontainers.image.documentation**: "https://docs.gitops.weave.works/"
<br/>**org.opencontainers.image.licenses**: The licenses this image falls under e.g., "MPL-2.0"
<br/>**org.opencontainers.image.revision**: Git Hash e.g., "db14c22923f5ba303bc3b0191acca93bb571739c",
<br/>**org.opencontainers.image.source**: URL for the source code e.g., "https://github.com/weaveworks/weave-gitops",
<br/>**org.opencontainers.image.title**: Typically the image name e.g., "wego-app",
<br/>**org.opencontainers.image.url**: URL for more information, e.g., "https://github.com/weaveworks/weave-gitops",
<br/>**org.opencontainers.image.vendor**: "Weaveworks"
<br/>**org.opencontainers.image.version**: Semantic version of the image (also the tag) e.g., "v0.3.3"

### Additional references 
* [OCI Image-spec annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md)
* [Docker Object meta data](https://docs.docker.com/config/labels-custom-metadata/)


## Consequences

This information will enable us to reproduce the image(s) they are running when troubleshooting customer environments.