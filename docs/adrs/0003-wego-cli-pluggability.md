# 3. Wego CLI pluggability

Date: 2021-08-13

## Status

Proposed

## Context

Wego has two touch primary user touch points the wego UI and the wego CLI.  Both will need to support core or free users and provide enhanced capabilities for the enterprise customers.  Solving the WebUI is covered in another ADR.

### Wego core built-in plugins/capabilities 
* Profiles (pctl)
* flux

### Known addon plugins
* Enterprise (EE)
  * workspaces (wk workspaces)
  * cluster create (mccp)

### Requirements
1. Extending the CLI must not require code changes in core
2. The core CLI won't know about the enterprise features (workspaces, clusters CAPI create)
3. The core CLI will support flux and profiles
4. The user has a single manual download for the core CLI
    * The CLI can optionally download dependencies at runtime
5. The wego enterprise CLI calls
    * wego cluster (create, update, delete, get) _actual flags TBD_
    * wego workspace (create, update, delete, get) _actual flags TBD_
6. The core CLI will need to may have a `cluster` noun
7. A Plugin can be used with multiple nouns 
    * `template` (for CAPI) calls into enterprise plugin
    * `cluster` calls into enterprise plugin
    * `workspace` calls into enterprise plugin
8. A plugin must be able to add additional flags to core commands
    * e.g., wego app add `--workspace foo`  --name blah --url 
        * If the enterprise plugin is installed, then the flag is recognized 

#### Future/stretch requirements
* ability to call out to a plugin from a built-in noun
  * e.g.,  wego app add --type pulmi --url --fobar ... calls the pulumi plugin to perform the app add

## Alternatives

### Separate wego enterprise CLI
* I.e. weave-gitops is an upstream project that is forked or vendored into wego-gitops-ee
* This approach is similar to the approach for the web UI

#### Pros
* Similar to the approach we are taking with the web UI
* Core and EE can move independently
* Simple matter of coding to augment core calls
* Minimal testing matrix

#### Cons
* Challenges with keeping EE up to date with core
    * Git tool does help 
* User needs a new wego CLI 
* Difficult for others to enhance wego CLI
* Lack of an extension model means more difficult to add capabilities later
* Additional build infrastructure 
* Potential additional cognitive load for engineers due to switching between code bases


### Add plugin model to wego core
* Add a facility, similar to how kubectl works, where plugins can be installed into a users path
    * Need the ability to associate one plugin with multiple nouns
        * unless changing the commands so that they identify the plugin.  e.g., wego ee templates get, wego ee cluster get

#### Pros
* Single wego CLI codebase and binary
* Defined plugin approach, which may increase adoption
* Potential to isolate changes and issues
* We don't have to spin a new wego CLI every time an issue is uncovered

#### Cons
* Each DevOps engineer will need to install the plugins
* Testing matrix can be difficult (core CLI * version) * (plugin + version)
* Depending on the approach, it may not be possible to extend existing commands (kubectl calls  this out specifically)

### Hybrid approach
If we can relax requirements 1 and 2 - we could add the commands for clusters, templates, and command flags but clearly indicate that they are enterprise-only features.  I've seen  many products have help strings with something similar to **(--enterprise only)**. The core CLI would be responsible for finding and calling the EE plugin.

The EE plugin could provide all flags and commands so that they are only in the plugin.  Having the plugin provide and sub-commands and flags, loosens the coupling as core would only have a command `template` and the help would print **(available in Weave GitOps EE)**

#### Pros
* Single core CLI code base
* Built-in advertising that some options are available if you upgrade
* Minimal changes to core CLI code base as the majority of the changes live in the EE plugin
* CLI upgrade only requires the new EE plugin

#### Cons
* Could upset users seeing commands they can't access
* Additional coordination/coupling between core and EE

### Plugin implementation options
* eksctl approach [eksctl PR](https://github.com/weaveworks/eksctl-private/pull/309/files)
    * will need to add dynamic plugin lookup
* kubectl plugin [Writing plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) [plugin handling](https://github.com/kubernetes/kubectl/blob/4defba0cec1f594eb410c69bff05b51cddfba8ff/pkg/cmd/cmd.go#L104)
* HashiCorp [go-plugin](https://github.com/HashiCorp/go-plugin/)
* golang [native plugins](https://pkg.go.dev/plugin)

## Decision
We will support two types of plugins in a phased approach.  We will support the noun-based plugins initially and add support for the command-based plugins in the future.

### Noun-based plugins
Add a section to the wego config file that allows a user to add plugins.  The fields are
* **noun** - The noun wego will use in the CLI, i.e., wego profile
* **name** - The name of the plugin
* **cmd** The executable plus optional parameters, similar to CMD in a Dockerfile
* **type** The type of the plugin (noun, cmd)
```yaml
   plugins
   - noun: workspace
     type: noun
     name: workspace
     cmd: 
     - /usr/local/bin/workspace
   - noun: cluster
     type: noun
     name: cluster
     cmd:
     - /usr/local/bin/mccp
     - cluster
   - noun: template 
     type: noun
     name: template
     cmd:
     - /usr/local/bin/mccp
     - template
```
The CLI will read the plugin configuration, and when encountering a noun from the plugins list, it will invoke the cmd with stdin, stdout, stderr, and environment mapped for the cmd.

Noun-based plugins will utilize a mechanism similar to kubectl and eksctl.  

### Command-based plugins
These plugins augment existing noun-verb commands with additional capabilities.  For example, we can extend the `wego app add` command with a new flag `--plugin kpt`, which will leverage the KPT plugin via well-defined interfaces using the HashiCorp go-plugin mechanism.
The config plugins section will add:
* **verbs** the list of verbs to tie to this plugin

```yaml
   plugins
   - moun: app
     verbs: 
     - add
     - get
     type: cmd
     name: kpt
     cmd: 
     - /usr/local/bin/kpt
```
The verb corresponds to a go-plugin interface that the cmd must implement.

## Consequences

Refer to the pros and cons listed with the alternatives
