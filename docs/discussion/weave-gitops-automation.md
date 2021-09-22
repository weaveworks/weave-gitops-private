# Overview
Designing and implementing Weave GitOps requires answering the question of how and where to store the automation resources used to manage user applications. The answer we choose has a variety of implications in at least the following areas:
1. Customer ease-of-use
2. Partitioning platform automation and application automation
3. Restoring a Weave GitOps environment after a cluster (or multiple cluster) failure
4. Upgrading Weave GitOps
5. Maintaining clarity and simplicity of the code base

The original design specified a single repository (the WeGO repository) which contained all automation manifests. It allowed no overlap between the automation repository and user application repositories. The designers intended to use git provider support to partition subsets of the automation. This made (3), (4), and (5) straightforward. However, our CTO at the time had two issues with the approach:
- She felt that requiring a user to create a separate WeGO repository presented a barrier to entry for the developer experience
- She wanted to support an independent "platform" automation repository managed by a separate platform team which would (among other things) store the automation for Weave GitOps itself

Further discussion let to the currently implemented model in which a user can decide on a per application basis where to store the relevant automation manifests. We resolved the CTO's first issue by allowing a user to store an application's automation within the application's own repository in a special hidden ".wego" directory. This freed the user from having to maintain a separate automation repository. We left her second issue unresolved with a plan to later define the relationship between a "platform" repository and the rest of a Weave GitOps installation. We intended the recent directory structure effort to come up with a plan for this as one of its outputs.

The designers realized early on in the discussions that including the automation within an application repository didn't entirely remove the developer barrier to entry. Installing an upstream helm chart or an application stored in a readonly git repository required creating a separate automation repository (since the user could not store the automation with the application). They worked around this by allowing a user to deploy an application without storing the automation outside of the cluster at all. This allowed for quick turnaround and easy experimentation but required a user to change the model when she was ready to deploy a real application.

## Current Model
As a result of the requirements mentioned above, we implemented a model in which a user provides an `app-config-url` when deploying an application. This URL flag indicates where the automation should reside:
- app-config-url=NONE (only in the cluster, not stored in any repository)
- app-config-url="" (the default, stored in a `.wego` directory within an application repository)
- app-config-url=&lt;URL> (stored in a separate automation repository)

We do not currently store the automation for Weave GitOps itself outside of the cluster as we planned to store it in the platform repository once we had one. We don't store the automation for a particular application's automation outside the cluster either (we have automation _for an application's automation_ because we want to manage the application's automation itself via GitOps allowing upgrade via pull requests, etc.). We currently have an issue with `gitops app remove` because that meta-automation resides only in the cluster. This prevents us from removing the application automation and _its_ automation together with a pull request. We have to remove the meta-automation directly from the cluster. This presents a chicken-and-egg problem. If we remove the meta-automation at the time we call `gitops app remove`, the associated pull request might remain unmerged for an arbitrarily long time leaving the system in a broken state. Alternatively, if we wait until a user merges the pull request, we have no way of knowing that we should then remove the meta-automation (without implementing a controller to track the relationship).

### Drawbacks of the Current Model
#### Code Complexity
Along with the issues around `gitops app remove`, the current model requires three distinct ways of managing automation manifests exemplified by this comment from `add.go`:

```
// Three models:
// --app-config-url=NONE
//
// - Source created for user repo (GitRepository or HelmRepository)
// - app.yaml created for app
// - HelmRelease or Kustomize created for app dir within user repo
// - app.yaml, Source, Helm Release or Kustomize applied directly to cluster
//
// --app-config-url=<URL>
//
// - Separate GOAT repo
// - Source created for GOAT repo
// - Kustomize created for targets/<target name> directory in GOAT repo
// - Kustomize created for apps/<app name> directory within GOAT repo
// - Source, Kustomizes applied directly to cluster
// - app.yaml created for app
// - app.yaml placed in apps/<app name>/app.yaml in GOAT repo
// - Source created for user repo (GitRepository or HelmRepository)
// - User repo Source placed in targets/<target name>/<app-name>/<app name>-gitops-runtime.yaml in GOAT repo
// - HelmRelease or Kustomize referencing user repo source created for user app dir within user repo
// - User app dir HelmRelease or Kustomize placed in targets/<target name>/<app name>/<app name>-gitops-runtime.yaml in GOAT repo
// - PR created or commit directly pushed for GOAT repo
//
// --app-config-url="" (default)
//
// - Source created for user repo (GitRepository only)
// - Kustomize created for .wego/targets/<target name> directory in user repo
// - Kustomize created for .wego/apps/<app name> directory within user repo
// - Source, Kustomizes applied directly to cluster
// - app.yaml created for app
// - app.yaml placed in apps/<app name>/app.yaml in .wego directory within user repo
// - HelmRelease or Kustomize referencing user repo source created for app dir within user repo
// - User app dir HelmRelease or Kustomize placed in targets/<target name>/<app name>/<app name>-gitops-runtime.yaml in .wego
//   directory within user repo
// - PR created or commit directly pushed for user repo
```

Before we move ahead with the new directory structure, we need to decide whether or not we want to maintain this tripartite approach.

#### Difficulties for Restore and Upgrade
For `restore`, even if we currently stored all the automation and meta-automation within repositories, the ability to select a repository per application means that we would either have to provide a list of all automation repositories to our restoration process or store such a list in a central location (we considered storing information like this in the platform repository but that would make the platform repository structure unique).

Upgrading Weave GitOps might require submitting and merging pull requests into an arbitrary set of repositories. I don't believe we can assume that a particular user would have permissions to update all of the repositories _and_ I don't know what situation a user would find herself in if she only completed a partial upgrade.

## New Directory Structure
The new directory structure described [here](https://github.com/weaveworks/weave-gitops-private/blob/main/docs/adrs/0007-directory-layout.md) supports _most_ of the same options as the current model. Specifically, it:
- allows for use of a single repository by storing application manifests in the automation repository and referencing them via kustomize files
- supports storing manifests for an application in a separate repository from the automation
- manages platform and meta-automation separately from application automation

It does not, however, easily support the "store automation only in the cluster" model. We will no longer have application-specific automation (which we could choose to store or not). Instead, a user will add an application or profile reference to a kustomization file (that gets synced) in order to add the corresponding application or profile to the cluster. We could conceivably make an entire Weave GitOps installation either "store automation" or "don't store automation" but I don't believe we can support doing one or the other per application.

Given the issues with `restore` and `upgrade`, combined with the extra complexity of porting the models to the new structure (and the mismatch between the new structure and the "don't store automation" model), we need to consider whether or not we get sufficient benefit from the per-application automation approach to continue supporting it. The directory structure document referenced above explicitly calls out using CODEOWNERS to manage modification permissions which also reduces the value of separate per-application automation repositories. Additionally, we can make the process of adding applications much simpler if we remove the `app-config-url` complexity and associate an automation repository in a separate step instead (or do it once in the first `add`).

If we decide we still get sufficient value from per-application automation, we can certainly map some of it onto the new directory structure; if not, however, we'll avoid a lot of wasted effort porting the model if we make the call before we switch.

