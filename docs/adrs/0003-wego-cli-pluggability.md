# 3. Wego CLI pluggability

Date: 2021-08-13

## Status

Proposed

## Context

Wego has two primary user touch points - the wego UI and the wego CLI.  Both will need to support core or free users and provide enhanced capabilities for paying, aka enterprise customers. This ADR focuses solely on the CLI.

The CLI needs to have a consistent interface whether the user is using the free or enterprise tier of the product.  The enterprise features will require validation that the user is _entitled or licensed_ to use the features.  The product _may_ hide enterprise features from users lacking the proper permissions.

This ADR proposes how we develop the Weave GitOps CLI to provide both core and enterprise capabilities.

_NOTE: The details of entitlement and licensing enforcement are not explicitly covered here._
### Wego core built-in plugins/capabilities 
* Profiles (pctl) - covered in this proposal 
* Flux - Ships as part of the CLI

### Known enterprise plugins/capabilities
* Enterprise (EE)
  * workspaces `wk workspaces`
  * cluster create `mccp`
* cluster reporting, aka mccp v1, TBD as it might move into the core

### CLI structure
The CLI today is structured as noun-verb.  Meaning, the first word after `wego` is the object or noun that the action will be performed on.  For example, `wego gitops install` and `wego app add`.
### Requirements
1. The core CLI will support flux and profiles
1. The user has a single manual download for the core CLI
    * The CLI can optionally download dependencies at runtime
1. The wego enterprise CLI calls
    * wego cluster (create, update, delete, get) _actual flags TBD_
    * wego workspace (create, update, delete, get) _actual flags TBD_
1. The core CLI may add a `cluster` noun
1. A single "plugin" may be used with multiple nouns 
    * `template` (for CAPI) calls into enterprise plugin
    * `cluster` calls into enterprise plugin
    * `workspace` calls into enterprise plugin

#### Future/stretch requirements
1. The ability to call out to a plugin from a built-in or core noun
    * e.g.,  wego app add --type pulmi --URL --foobar ... calls the pulumi plugin to perform the app add
1. A plugin should be able to add additional flags to core commands
    * e.g., wego app add `--workspace foo`  --name blah --URL 
        * If the enterprise plugin is installed, then the flag is recognized 
1. Extending the CLI shouldn't require code changes in the core software
1. The core CLI shouldn't know about the enterprise features (workspaces, clusters CAPI create)

## Alternatives

### Separate wego enterprise CLI
* I.e., weave-gitops is an upstream project that is forked or vendored (go modules) into Weave GitOps EE
* This approach is similar to the approach for the web UI

#### Pros
* Similar to the approach we are taking with the web UI
* Core and EE can move independently
* Simple matter of coding to augment core calls
  * It's a simple matter as there is a wegoee CLI _note: wegoee is an example name_
* Minimal testing matrix
  * Core version tests only core features.  Core tests should pass for the wegoee CLI

#### Cons
* Challenges with keeping EE up to date with core
    * Git tooling does provide some assistance 
* User needs a new wego CLI 
* Difficult for others to enhance wego CLI - they would follow a similar pattern
* Lack of an extension model means more difficult to add capabilities later
* Additional build infrastructure 
* Potential additional cognitive load for engineers due to switching between codebases


### Add plugin model to wego core
* Add a facility, similar to how kubectl works, where plugins can be installed into a users path
    * Need the ability to associate one plugin with multiple nouns
        * unless changing the commands so that they identify the plugin.  e.g., wego ee templates get, wego ee cluster get  (the `ee` is the noun and identifies the plugin)

#### Pros
* Single wego CLI codebase and binary - we don't need to build a `wegoee` CLI
  * The enterprise functionality is still a separate binary
* Defined plugin approach, which may increase adoption as it's easy to extend
* Potential to isolate changes and issues
* A critical issue in core doesn't require a new version of EE and vice versa

#### Cons
* Each DevOps engineer will need to install the plugins
* Testing matrix can be difficult (core CLI * version) * (plugin * version)
  * Weave GitOps core is only responsible for the plugin mechanism itself, and testing of the actual plugins would remain in the enterprise version
* Depending on the approach, it may not be possible to extend existing commands (kubectl calls this out specifically)

### Hybrid approach
If we can relax stretch requirements 1 and 2 - we could add the commands for clusters, templates, and command flags but clearly indicate that they are enterprise-only features.  Many products have help strings with something similar to **(--enterprise only)**. The core CLI would be responsible for finding and calling the EE plugin.

The EE plugin could provide all flags and commands so that they are only in the plugin.  Having the plugin provide any sub-commands and flags loosens the coupling as the core would only have a noun e.g., `template`, and the help would print **(available in Weave GitOps EE)**

#### Pros
* Single core CLI codebase
* Built-in advertising that some options are available if you upgrade
* Minimal changes to core CLI code base as the majority of the changes live in the EE plugin
* CLI upgrade only requires a new EE plugin

#### Cons
* Could upset users seeing commands they can't access
* Additional coordination/coupling between core and EE

### Tolkien approach
If we can relax stretch requirements 1 and 2 - we could add the commands for clusters, templates, and command flags but clearly indicate that they are enterprise-only features.  Many products have help strings with something similar to **(--enterprise only)**. The commands will look for either an entitlement/license and/or the presence of backend APIs to know if the user has permissions to execute this command.

The wego CLI will replace the Multi-cluster control plane CLI, `mccp`, and the workspace CLI, `wk workspace`.  The profiles CLI, `pctl` will remain a separate CLI.  However, Weave GitOps will provide equivalent commands into `wego`.

#### Pros
* Single **CLI** codebase _Refer to the sample code below on integrating profiles._
* Single **CLI** for all Weave GitOps functionality 
* Built-in advertising that some options are available if you upgrade
* Easiest approach for development
* No CLI upgrade required
* Single set of documentation

#### Cons
* Could upset users seeing commands they can't access
* Core CLI must maintain a certain level of backward capability
* No plugin/extension mechanism
* We will need to clearly indicate core vs. enterprise features in the documentation

### Plugin implementation options
* eksctl approach [eksctl PR](https://github.com/weaveworks/eksctl-private/pull/309/files)
    * will need to add dynamic plugin lookup
* kubectl plugin [Writing plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/) [plugin handling](https://github.com/kubernetes/kubectl/blob/4defba0cec1f594eb410c69bff05b51cddfba8ff/pkg/cmd/cmd.go#L104)
* HashiCorp [go-plugin](https://github.com/HashiCorp/go-plugin/)
* golang [native plugins](https://pkg.go.dev/plugin)

## Decision
We will take the Tolkien approach for the following reasons:
* We want users and customers to have a single CLI to interact with
* We want to remove barriers and friction on the internal development of the CLI
* To simplify the Weave GitOps upgrade process for customers
* To inform the user that they can unlock additional capabilities 
* To reduce the documentation burden
* To develop the CLI in the open

## Consequences

* EOL'ing/replacing the `mccp` and `wk workspace` CLI
* The CLI commands will be developed in the open using the wego-core public repository 
* Enterprise-only changes will necessitate a new release of the Weave GitOps CLI - meaning core users will upgrade but receive no new capabilities
* In addition to documentation, CLI release notes will need to clearly indicate changes between core and enterprise

## Sample code
Adding a `profile` command to wego would be similar to the following.  
``` diff
diff --git a/cmd/wego/main.go b/cmd/wego/main.go
index e9918a5..f46036f 100644
--- a/cmd/wego/main.go
+++ b/cmd/wego/main.go
@@ -9,6 +9,7 @@ import (
 	"github.com/weaveworks/weave-gitops/cmd/wego/app"
 	"github.com/weaveworks/weave-gitops/cmd/wego/flux"
 	"github.com/weaveworks/weave-gitops/cmd/wego/gitops"
+	"github.com/weaveworks/weave-gitops/cmd/wego/profile"
 	"github.com/weaveworks/weave-gitops/cmd/wego/ui"
 	"github.com/weaveworks/weave-gitops/cmd/wego/version"
 	fluxBin "github.com/weaveworks/weave-gitops/pkg/flux"
@@ -100,6 +101,7 @@ func main() {
 	rootCmd.AddCommand(ui.Cmd)
 
 	rootCmd.AddCommand(app.ApplicationCmd)
+	rootCmd.AddCommand(profile.RootCmd)
 
 	if err := rootCmd.Execute(); err != nil {
 		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
diff --git a/cmd/wego/profile/add.go b/cmd/wego/profile/add.go
new file mode 100644
index 0000000..1af7448
--- /dev/null
+++ b/cmd/wego/profile/add.go
@@ -0,0 +1,40 @@
+/*
+Copyright © 2021 Weaveworks <support@weave.works>
+This file is part of CLI application wego.
+*/
+package profile
+
+import (
+	"fmt"
+
+	"github.com/spf13/cobra"
+)
+
+// addCmd represents the add command
+var addCmd = &cobra.Command{
+	Use:   "add",
+	Short: "A brief description of your command",
+	Long: `A longer description that spans multiple lines and likely contains examples
+and usage of using your command. For example:
+
+Cobra is a CLI library for Go that empowers applications.
+This application is a tool to generate the needed files
+to quickly create a Cobra application.`,
+	Run: func(cmd *cobra.Command, args []string) {
+		fmt.Println("add called")
+	},
+}
+
+func init() {
+	RootCmd.AddCommand(addCmd)
+
+	// Here you will define your flags and configuration settings.
+
+	// Cobra supports Persistent Flags which will work for this command
+	// and all subcommands, e.g.:
+	// addCmd.PersistentFlags().String("foo", "", "A help for foo")
+
+	// Cobra supports local flags which will only run when this command
+	// is called directly, e.g.:
+	// addCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
+}
diff --git a/cmd/wego/profile/delete.go b/cmd/wego/profile/delete.go
new file mode 100644
index 0000000..2339371
--- /dev/null
+++ b/cmd/wego/profile/delete.go
@@ -0,0 +1,40 @@
+/*
+Copyright © 2021 Weaveworks <support@weave.works>
+This file is part of CLI application wego.
+*/
+package profile
+
+import (
+	"fmt"
+
+	"github.com/spf13/cobra"
+)
+
+// deleteCmd represents the delete command
+var deleteCmd = &cobra.Command{
+	Use:   "delete",
+	Short: "A brief description of your command",
+	Long: `A longer description that spans multiple lines and likely contains examples
+and usage of using your command. For example:
+
+Cobra is a CLI library for Go that empowers applications.
+This application is a tool to generate the needed files
+to quickly create a Cobra application.`,
+	Run: func(cmd *cobra.Command, args []string) {
+		fmt.Println("delete called")
+	},
+}
+
+func init() {
+	RootCmd.AddCommand(deleteCmd)
+
+	// Here you will define your flags and configuration settings.
+
+	// Cobra supports Persistent Flags which will work for this command
+	// and all subcommands, e.g.:
+	// deleteCmd.PersistentFlags().String("foo", "", "A help for foo")
+
+	// Cobra supports local flags which will only run when this command
+	// is called directly, e.g.:
+	// deleteCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
+}
diff --git a/cmd/wego/profile/get.go b/cmd/wego/profile/get.go
new file mode 100644
index 0000000..1757d84
--- /dev/null
+++ b/cmd/wego/profile/get.go
@@ -0,0 +1,40 @@
+/*
+Copyright © 2021 Weaveworks <support@weave.works>
+This file is part of CLI application wego.
+*/
+package profile
+
+import (
+	"fmt"
+
+	"github.com/spf13/cobra"
+)
+
+// getCmd represents the get command
+var getCmd = &cobra.Command{
+	Use:   "get",
+	Short: "A brief description of your command",
+	Long: `A longer description that spans multiple lines and likely contains examples
+and usage of using your command. For example:
+
+Cobra is a CLI library for Go that empowers applications.
+This application is a tool to generate the needed files
+to quickly create a Cobra application.`,
+	Run: func(cmd *cobra.Command, args []string) {
+		fmt.Println("get called")
+	},
+}
+
+func init() {
+	RootCmd.AddCommand(getCmd)
+
+	// Here you will define your flags and configuration settings.
+
+	// Cobra supports Persistent Flags which will work for this command
+	// and all subcommands, e.g.:
+	// getCmd.PersistentFlags().String("foo", "", "A help for foo")
+
+	// Cobra supports local flags which will only run when this command
+	// is called directly, e.g.:
+	// getCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
+}
diff --git a/cmd/wego/profile/root.go b/cmd/wego/profile/root.go
new file mode 100644
index 0000000..4268908
--- /dev/null
+++ b/cmd/wego/profile/root.go
@@ -0,0 +1,75 @@
+/*
+Copyright © 2021 Weaveworks <support@weave.works>
+This file is part of CLI application wego.
+*/
+package profile
+
+import (
+	"fmt"
+	"os"
+
+	"github.com/spf13/cobra"
+
+	"github.com/spf13/viper"
+)
+
+var cfgFile string
+
+// RootCmd represents the base command when called without any subcommands
+var RootCmd = &cobra.Command{
+	Use:   "profile",
+	Short: "A brief description of your application",
+	Long: `A longer description that spans multiple lines and likely contains
+examples and usage of using your application. For example:
+
+Cobra is a CLI library for Go that empowers applications.
+This application is a tool to generate the needed files
+to quickly create a Cobra application.`,
+	// Uncomment the following line if your bare application
+	// has an action associated with it:
+	// Run: func(cmd *cobra.Command, args []string) { },
+}
+
+// Execute adds all child commands to the root command and sets flags appropriately.
+// This is called by main.main(). It only needs to happen once to the RootCmd.
+func Execute() {
+	cobra.CheckErr(RootCmd.Execute())
+}
+
+func init() {
+	cobra.OnInitialize(initConfig)
+
+	// Here you will define your flags and configuration settings.
+	// Cobra supports persistent flags, which, if defined here,
+	// will be global for your application.
+
+	RootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.profile.yaml)")
+
+	// Cobra also supports local flags, which will only run
+	// when this action is called directly.
+	RootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
+}
+
+// initConfig reads in config file and ENV variables if set.
+func initConfig() {
+	if cfgFile != "" {
+		// Use config file from the flag.
+		viper.SetConfigFile(cfgFile)
+	} else {
+		// Find home directory.
+		home, err := os.UserHomeDir()
+		cobra.CheckErr(err)
+
+		// Search config in home directory with name ".profile" (without extension).
+		viper.AddConfigPath(home)
+		viper.SetConfigType("yaml")
+		viper.SetConfigName(".profile")
+	}
+
+	viper.AutomaticEnv() // read in environment variables that match
+
+	// If a config file is found, read it in.
+	if err := viper.ReadInConfig(); err == nil {
+		fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
+	}
+}
```
