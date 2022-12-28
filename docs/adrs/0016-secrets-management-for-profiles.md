# 16. secrets management for profiles from private helm repositories

## Status

Proposed

## Context
As part of Weave GitOps Enterprise, Timberwolf is working on delivering [Secrets Management](https://www.notion.so/weaveworks/Secrets-Management-f6add2cba4be4faa8bbad1276fb0455e).
One of the use cases to enable by this initiative is to be able to use [weave gitops profiles](https://docs.gitops.weave.works/docs/cluster-management/profiles/)
from [private helm repositories](https://fluxcd.io/flux/guides/helmreleases/#helm-repository-authentication-with-credentials).

This is a common scenario for enterprises willing to use profiles but having to use an off-road solution or non-long
term solution for enterprise like using public helm repositories. Another major requirement is that it should 
work with any infrastructure provisioning approach, where [Cluster API](https://docs.gitops.weave.works/docs/cluster-management/cluster-api-providers/) 
is one of them but not only. Lastly, it should consider work for both creation and update. 

This ADR states the different alternatives in the solution space and selects the ones that enable
enterprises using the feature securely. 

## Decision

In order to enable this scenario within weave gitops and secrets management there are currently the following 
possible routes:

1. To Sync the private helm repo credentials as part of cluster bootstrapping before flux is in the cluster. 
   - Same [approach](https://github.com/weaveworks/profiles-catalog/tree/main/charts/external-secrets#how-to-install-with-wge-on-kubernetes-cluster) as the initial secrets via ClusterResourceSet.
   - This solution won't be feasible as it would only work for CAPI clusters. 
2. To create a public helm repo for storing the [external secret manifests](https://external-secrets.io/v0.7.0/api/externalsecret/)
    - This solution won't be enterprise grade as it wont meet enterprise security requirements. 
3. Same as 2) but within the enterprise network so the access is not accessible outside the enterprise network.  
    - This solution might work for some enterprise, but it is not a solution that we could generally say it will be accepted by enterprises.e
4. To extend, secrets management provisioning to include platform secrets like the helm profiles.
    - This solution would work as follows:
      1. the private helm repo secret exists in either git as sops or in an external secret store
      2. during secrets management bootstrapping you are able to select a set of secrets to sync from 1) living in git  
      3. after secrets management bootstrapping you have bootstrapped both secrets management solution and the private helm repo secret
      4. profiles from private repo could be installed using secrets from 3)
    - Limitations: it would only work for secrets management bootstrapping (creation) but not when the secret has changed (update / rotation).
5. Variations of 4 like having a zero-layer profile with external platform secrets.
   - This solution would work as 4 but having a different profile from git with the secrets to sync



---

follow user journey could be followed:

1. You have a supported secrets store and a the secret with the authN details for the private helm repo that you want to reference in your profile.
2. You have provisioned [external secrets profile](https://www.notion.so/Secrets-Management-f6add2cba4be4faa8bbad1276fb0455e) within your cluster and it is able to sync secrets from the previous secret store.
3. Your profile, defines an [ExternalSecret](https://external-secrets.io/v0.7.0/api/externalsecret/) to sync
4. Your HelmRelease references the Secret created out of the previous step
5. There is a need for orchestration between the helm release installed event and secret provisioned (by ESO) event

Pro

- independent of the cluster

Limitations

- the external secret reference needs to exists within target profile, so it could be duplicated among profiles from the same helm repo
- is there an orchestration issue between secrets management gets installed and the profile that requires it?
## Consequences

TBA