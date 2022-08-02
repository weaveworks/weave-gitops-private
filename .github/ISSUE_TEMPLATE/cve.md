---
name: CVE
about: Create a report to help us improve
title: ''
labels: cve
assignees: ''

---
Investigation done in https://github.com/weaveworks/weave-gitops-enterprise/issues/1115#issuecomment-1190135214

[CVE Handling process
](https://docs.google.com/document/d/15vsta8H4gXQkpSjRVTQH1o3KrwgOY5H4c8ydNgrHt-I/edit)

- [x] Weaveworks team receives a notification about a security vulnerability, acknowledges it, and creates a private issue to track its progress.
    - Kevin raised concerns after reading https://blog.argoproj.io/2022-argo-external-security-audit-lessons-learned-951f80e0450d
- [x] The vulnerability is treated as highest priority and directed to the respective product or services team.
- [x] The product or services team evaluates the vulnerability with help from the Weaveworks security team.
- [x] ~If the vulnerability does not pose a threat to the product or service, Weaveworks responds back with proper reasoning.~ It does.
- [x] ~If the reported vulnerability is an actual threat, Weaveworks responds back, accepting the issue.~ Internally discovered
- [x] The product team provides a workaround, if available to the reporter.
- [x] The product team works to identify a fix and produce a time estimation (ETA) to create the patch for the product or service.
    - We just tried to fix it as asap. It took us about ~1week to release rc versions of both core/ee that had a fix.
- [x] Weaveworks add a 1-month buffer to the ETA to come up with a proposed public announcement date.
    - To make it public August 27th 2022
- [x] ~According to Weaveworks responsible disclosure ethics, we inform the public announcement date to the issue reporter first. If the reporter agrees to making the vulnerability information public, then the information will be announced after the previously set public announcement date.~
    - Discovered internally.
- [ ] Initiate the patch creation process.
    - ? Describe steps to apply the fix to a deployment ? (probably upgrading to a new release, but perhaps not always).
- [ ] Create a Security Advisory for the vulnerability, informing its impact and the mitigation steps.
    - Started [CVE-1126](https://docs.google.com/document/d/1rXGLZKXus9DnmToMBiDZ7sTMkG-luW9AutLLoffrwjQ)
- [ ] The patch/update is provided to the reporter and all affected customers.
    - Create a list of effected customers etc, who owns this? Maybe CX.
- [ ] A public security advisory will be issued after all the patches are issued to the customers and the buffer period is exceeded.
    - Where does this go? On a blog? website? Talk to marketing about timing / wording?

## Details

Malicious links can be crafted by users by editing kubernetes resources, these are then shown in the UI. Two instances of this vulnerability are known.

### Execution

In both these cases the user would have to be able to change objects in the cluster somehow. Either:
- directly via `kubectl` if they have RBAC permissions
- updating the git repository (github/gitlab) and have flux sync the changes.

### 1. weave-gitops-enterprise: GitopsCluster dashboard links can be crafted maliciously

```yaml
apiVersion: gitops.weave.works/v1alpha1
kind: GitopsCluster
metadata:
  name: demo-02
  namespace: default
  annotations:
    metadata.weave.works/dashboard.hellothere: "javascript:alert('hello there ' + window.localStorage.getItem('name'));"
```

Will show a link that says "hellothere" but then will execute JS when clicked

#### Workaround

Do not allow users to add or change `GitopsCluster` objects

#### Severity: 7

The code that will be executed is **hidden**, but it is most likely only admins that can make changes to the gitrepo and RBAC to change `GitopsCluster` resources.


#### Affects versions

Introduced in EE in https://github.com/weaveworks/weave-gitops-enterprise/commit/90cfafcc3206d63ead63c4f0bbbbb584363357c4

```
$ git tag --contains 90cfafcc3206d63ead63c4f0bbbbb584363357c4 --no-contains 48645ccc316c44cb309ba35ed5c4599890916247 --sort creatordate | cat
v0.8.1
v0.9.0-rc.1
v0.9.0-rc.2
v0.9.0-rc.3
v0.9.0-rc.4
```

#### Fix

Fixed in https://github.com/weaveworks/weave-gitops-enterprise/pull/1122 on `main` as https://github.com/weaveworks/weave-gitops-enterprise/commit/48645ccc316c44cb309ba35ed5c4599890916247

Versions with the fix:

```
$ git tag --contains 48645ccc316c44cb309ba35ed5c4599890916247 --sort creatordate | cat
v0.9.0-rc.5
```

### 2. weave-gitops: `HelmRepository.spec.url` can be crafted maliciously

```yaml
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: HelmRepository
spec:
  url: "javascript:alert(1);"
```

Will show the string `javascript:alert(1);` in the sources table, which when clicked will be executed.

#### Workaround

Do not allow users to add or change `HelmRepository` objects

#### Severity: 6

The code that will be executed is **show** directly in the UI before you click on it. But it is most likely only admins that can make changes to the gitrepo and RBAC to change `HelmRepo` resources.

#### Weave Gitops

#### Affects versions

Introduced in https://github.com/weaveworks/weave-gitops/commit/87c431a312af861b3a96f6ba296beb5d09d47747

```
$ git tag --contains 87c431a312af861b3a96f6ba296beb5d09d47747 --no-contains 01c6216ab6360669ae5fc12121d8beb8e4464737 --sort creatordate | cat
v0.7.0-rc1
v0.7.0-rc2
v0.7.0-rc3
v0.7.0-rc4
v0.7.0-rc5
v0.7.0-rc7
v0.7.0-rc8
v0.7.0-rc9
v0.7.0-rc10
v0.7.0-rc11
v0.7.0-rc12
v0.7.0-rc13
v0.7.0
v0.7.0-patch1
v0.7.1-rc.1
v0.7.1-rc.2
v0.7.1-rc.3
v0.8.0-rc.1
v0.8.0-rc.2
v0.8.0
v0.8.1-rc.1
v0.8.1-rc.2
v0.8.1-rc.3
v0.8.1-rc.4
v0.8.1-rc.5
v0.8.1-rc.6
v0.8.1-rc.7
v0.8.1
v0.9.0-rc.1
v0.9.0-rc.2
v0.9.0-rc.3
v0.9.0
v0.9.1-rc.1
```

#### Fix

Fixed in https://github.com/weaveworks/weave-gitops/pull/2470 on `main` as https://github.com/weaveworks/weave-gitops/commit/01c6216ab6360669ae5fc12121d8beb8e4464737

Versions with fix

```
$ git tag --contains 01c6216ab6360669ae5fc12121d8beb8e4464737 --sort creatordate | cat
v0.9.1-rc.2
v0.9.1
```

#### Weave Gitops Enterprise

#### Affects versions

Introduced into EE in e67f4a770ad3f6a673017fd94af38820fc19aeb0

```
$ git tag --contains e67f4a770ad3f6a673017fd94af38820fc19aeb0 --no-contains 7f14c46e273ddfb988ff3213ea23b1815cd3200c --sort creatordate | cat
v0.7.0-rc.1
v0.7.0-rc.2
v0.8.0-rc.1
v0.8.1-rc.1
v0.8.1-rc.2
v0.8.1-rc.3
v0.8.1
v0.9.0-rc.1
v0.9.0-rc.2
v0.9.0-rc.3
v0.9.0-rc.4
```

#### Fix

Fixed when upgrade to weave-gitops@0.9.1-rc.2 in 7f14c46e273ddfb988ff3213ea23b1815cd3200c

```
$ git tag --contains  7f14c46e273ddfb988ff3213ea23b1815cd3200c --sort creatordate | cat
v0.9.0-rc.5
```
