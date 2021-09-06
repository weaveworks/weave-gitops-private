# 8. Feature flags

Date: 2021-09-05

## Status

Proposed

## Context

As our organization grows, we will have more developers and more work in flight.  This can result is long-lived branches, complicated testing environments, and slower release cycles.  Using feature branches allows us to develop closer to the trunk and separate releasing from delivering software. In addition, feature flags can be used for beta testing new features without special builds, operational controls, for example kill switches, progressive and ring-based deployments, and in some cases features available by product tiers

Feature flags can be simple environment variables passed into a program or a SaaS service used to define, serve, and check flags at runtime.

### Goals
Provide feature flags to hid functionality in CLIs, Web UIs, Kubernetes components (controllers, services). Separate deploy from release. Enable trunk-based dev.  

### General info
Some of the solutions evaluate the flags on the server and some on the client.  Benefit of the server is we can track usage of the flags and this will enable us to determine obsolete flags, and track user data for a/b testing.  However, problems with checking them on the serve is data leaves the users environment and server-side checking can make it more difficult to support air-gapped environments.

### Requirements
* Golang client lib
* javascript/typescript lib
* Work in air gapped environments
* Boolean flags
* Scalar data types
* Ability for end user to disable checks
* Target features to users
* Progressive rollout

#### Nice to have 
* server-less option - i.e., passing commandline or environment settings
* Replace checkpoint system with more detailed telemetry metrics
* Ability to target features to certain users and goups of users
* Scheduled rollout of new features. e.g., on Friday at 0800, enable feature X
* Service offering 

### Alternatives
* LaunchDarkly https://launchdarkly.com/
* dcdr (decider) https://github.com/vsco/dcdr
* Unleash https://github.com/Unleash/unleash
* Optimizly rollouts https://www.optimizely.com/rollouts/?ref=nav
* split.io https://www.split.io
* Petri https://github.com/wix-incubator/petri
* Flipt.io https://github.com/markphelps/flipt 
* Configcat https://configcat.com/

#### LaunchDarkly
##### Pricing
* Separate server-side from client-side MAUs. 
* Need a seat for each person interacting with the service
  *  Start is $10 per seat (only 1k client side MAUs), $20 per seat gives us 10k client MAUs
  *  $200 a month, or $165 with an annual contract

##### Offline mode
* with the enterprise version, we can have a relay proxy that loads all the feature flag information from a local file
* Not technicall offline as the relay runs localy in the environment

##### General
* Doesn't appear to have an eventing system to replace checkpoint
* Pushes feature changes to the SDK meaning kill switches can be seen almost immediately 

#### Unleash
##### Pricing
* Opeen source, self host free
* www.getunleash.io - pro $80 (5 team members) $15 each additional team member - $155
  *  Max of 20 team members
##### Offline mode
* Yes via a proxy
##### General
* GitLab offers feature flags using this tech - but don't use it internally
* Don't see an eventing solution for track experiments and replacing checkpoint
* Unless you use the proxy, the toggles are evaluated on the server.  Meaning client data is sent from the application
* In my testing (docker DB, Docker Unleash) my application didn't see when the toggle switched from enabled to disabled.
   * adding a call to wait for the client to be ready solved this issue.
* Confusing application concept

#### Split
##### Pricing
* Priced by MTK (Monthly Tracked Keys) + User Seats (how we identify clustomers)
* Free tier 10 seats
* Platform tier (no prices on the web)
##### General
* They have an events part of the API which could replace checkpoint


#### Optimizely
##### Pricing
* The rollouts project is free
* No pricing details on web
##### General
* Has events for tracking experiments - might be use to replace checkpoint

#### Configcat
##### Pricing
* easiest to understand
* Not user or team sized pricing
* Start for free - but likely need the 300 a month plan
* Limited by the number of config.json downloads

##### General
* Evaluated client-side - user's data doesn't leave the system
* No option to replace checkpoint
* Poll based - can have web hooks for push.  Limited number.
##### Questions
* Air gapped solution - yes, you can distribute the config.json file and have it used locally

#### flipt
##### Pricing
* Free - self hosted

##### General
* active project
* built in go
* supports both gRPC and http integratioon
* License is GPL-3
* Server component that performs the evaluation which means some customer data is sent outside the env

#### Dcdr 
##### Pricing
* Free

##### General
* I like the design - client makes the decisions
* built for distributed use - consul, etcd are the primary datastores
* license is MIT
* project seems stale - no recent releases

## Shortlist
* ConfigCat - simple pricing model, lots of OSS clients
* flipt - OSS we generate the clients via protobuf, easy to get up and running
* unleash - OSS but I did have issues when testing

### Exmple code

#### Configcat
```bash
diff --git a/cmd/wego/app/cmd.go b/cmd/wego/app/cmd.go
index 1267c45..90bc81c 100644
--- a/cmd/wego/app/cmd.go
+++ b/cmd/wego/app/cmd.go
@@ -1,6 +1,9 @@
 package app
 
 import (
+       "os"
+
+       configcat "github.com/configcat/go-sdk/v7"
        "github.com/spf13/cobra"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/add"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/list"
@@ -13,7 +16,12 @@ var ApplicationCmd = &cobra.Command{
 }
 
 func init() {
+       user := &configcat.UserData{Identifier: "0.2.0"} // Unique identifier is required. Could be UserID, Email address or SessionID.
+       client := configcat.NewClient(os.Getenv("CC_KEY"))
+       listCmd := client.GetBoolValue("listCmd", false, user)
        ApplicationCmd.AddCommand(status.Cmd)
        ApplicationCmd.AddCommand(add.Cmd)
-       ApplicationCmd.AddCommand(list.Cmd)
+       if listCmd {
+               ApplicationCmd.AddCommand(list.Cmd)
+       }
 }
diff --git a/go.mod b/go.mod
index d3363c1..097fa14 100644
--- a/go.mod
+++ b/go.mod
@@ -3,6 +3,7 @@ module github.com/weaveworks/weave-gitops
 go 1.16
 
 require (
+       github.com/configcat/go-sdk/v7 v7.0.0 // indirect
        github.com/deepmap/oapi-codegen v1.8.1
        github.com/dnaeon/go-vcr v1.2.0
        github.com/fluxcd/go-git-providers v0.1.1
```
#### flipt 

```bash
diff --git a/cmd/wego/app/cmd.go b/cmd/wego/app/cmd.go
index 1267c45..79a6aef 100644
--- a/cmd/wego/app/cmd.go
+++ b/cmd/wego/app/cmd.go
@@ -1,10 +1,17 @@
 package app
 
 import (
+       "context"
+       "flag"
+       "log"
+       "os"
+
+       flipt "github.com/markphelps/flipt-grpc-go"
        "github.com/spf13/cobra"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/add"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/list"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/status"
+       "google.golang.org/grpc"
 )
 
 var ApplicationCmd = &cobra.Command{
@@ -12,8 +19,46 @@ var ApplicationCmd = &cobra.Command{
        Args: cobra.MinimumNArgs(1),
 }
 
+type data struct {
+       FlagKey     string
+       FlagName    string
+       FlagEnabled bool
+}
+
+var (
+       fliptServer string
+       flagKey     string
+)
+
 func init() {
+       flag.StringVar(&fliptServer, "server", "localhost:9000", "address of Flipt backend server")
+       flag.StringVar(&flagKey, "flag", "listcmd", "flag key to query")
+       flag.Parse()
+       conn, err := grpc.Dial(fliptServer, grpc.WithInsecure())
+       if err != nil {
+               log.Fatal(err)
+       }
+       defer conn.Close()
+
+       log.Printf("connected to Flipt server at: %s", fliptServer)
+
+       client := flipt.NewFliptClient(conn)
+       flag, err := client.GetFlag(context.Background(), &flipt.GetFlagRequest{
+               Key: flagKey,
+       })
+       if err != nil {
+               log.Printf("Failed to connect and get key %e \n", err)
+               os.Exit(1)
+       }
+
+       if flag == nil {
+               log.Println("Key not found")
+               return
+       }
+
        ApplicationCmd.AddCommand(status.Cmd)
        ApplicationCmd.AddCommand(add.Cmd)
-       ApplicationCmd.AddCommand(list.Cmd)
+       if flag.Enabled {
+               ApplicationCmd.AddCommand(list.Cmd)
+       }
 }
diff --git a/go.mod b/go.mod
index d3363c1..c045c8e 100644
--- a/go.mod
+++ b/go.mod
@@ -16,6 +16,7 @@ require (
        github.com/grpc-ecosystem/protoc-gen-grpc-gateway-ts v1.1.1
        github.com/jandelgado/gcov2lcov v1.0.5
        github.com/lithammer/dedent v1.1.0
+       github.com/markphelps/flipt-grpc-go v0.3.0 // indirect
        github.com/maxbrunsfeld/counterfeiter/v6 v6.4.1
        github.com/onsi/ginkgo v1.16.4
        github.com/onsi/gomega v1.13.0
@@ -25,10 +26,11 @@ require (
        github.com/spf13/cobra v1.1.3
        github.com/stretchr/testify v1.7.0
        github.com/weaveworks/go-checkpoint v0.0.0-20170503165305-ebbb8b0518ab
-       golang.org/x/net v0.0.0-20210510120150-4163338589ed // indirect
+       golang.org/x/net v0.0.0-20210614182718-04defd469f4e // indirect
+       golang.org/x/sys v0.0.0-20210630005230-0f9fa26af87c // indirect
        golang.org/x/term v0.0.0-20210615171337-6886f2dfbf5b
-       google.golang.org/genproto v0.0.0-20210617175327-b9e0b3197ced
-       google.golang.org/grpc v1.38.0
+       google.golang.org/genproto v0.0.0-20210708141623-e76da96a951f
+       google.golang.org/grpc v1.39.0
        google.golang.org/grpc/cmd/protoc-gen-go-grpc v1.1.0
        google.golang.org/protobuf v1.27.1
        gopkg.in/yaml.v2 v2.4.0
```

#### Unleash
```bash
diff --git a/cmd/wego/app/cmd.go b/cmd/wego/app/cmd.go
index 1267c45..58b877f 100644
--- a/cmd/wego/app/cmd.go
+++ b/cmd/wego/app/cmd.go
@@ -1,6 +1,9 @@
 package app
 
 import (
+       "net/http"
+
+       "github.com/Unleash/unleash-client-go/v3"
        "github.com/spf13/cobra"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/add"
        "github.com/weaveworks/weave-gitops/cmd/wego/app/list"
@@ -13,7 +16,17 @@ var ApplicationCmd = &cobra.Command{
 }
 
 func init() {
+       unleash.Initialize(
+               unleash.WithListener(&unleash.DebugListener{}),
+               unleash.WithAppName("wego"),
+               unleash.WithUrl("http://localhost:4242/api"),
+               unleash.WithCustomHeaders(http.Header{"Authorization": {"fbd4845725b20aa00d023bb3e57dcc15775848d2e667974afd101aa011921a52"}}),
+       )
        ApplicationCmd.AddCommand(status.Cmd)
        ApplicationCmd.AddCommand(add.Cmd)
-       ApplicationCmd.AddCommand(list.Cmd)
+       unleash.WaitForReady()
+       if unleash.IsEnabled("listCmd") {
+               ApplicationCmd.AddCommand(list.Cmd)
+       }
+
 }
diff --git a/go.mod b/go.mod
index d3363c1..5814cf9 100644
--- a/go.mod
+++ b/go.mod
@@ -3,6 +3,7 @@ module github.com/weaveworks/weave-gitops
 go 1.16
 
 require (
+       github.com/Unleash/unleash-client-go/v3 v3.2.3 // indirect
        github.com/deepmap/oapi-codegen v1.8.1
        github.com/dnaeon/go-vcr v1.2.0
        github.com/fluxcd/go-git-providers v0.1.1
```


## Decision

Use a feature management system, [ConfigCat](https://app.configcat.com/)

## Consequences

Feature flags will enable us to add EE CLI options to the core CLI and expose them for our internal development and testing.  Enabling us to release new versions of the CLI without concern for end users interacting with the capabilities before we are ready.  Giving us a single CLI, released as frequently as we need.
