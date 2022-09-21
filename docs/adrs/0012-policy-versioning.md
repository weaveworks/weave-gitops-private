# 12. Policy versioning

Date: 2022-9-4

## Status

Accepted

## Context

There is no clear way to manage the release of the policy agent. As it stands now the agent is considered to be released when it pushes to the latest tag. This creates a problem with the charts and profiles that make use of the agents, since they would be used a non fixed version that would change depending on the time the agent was deployed. In addition to that the agent itself depends on policies to be able to perform its operation. This usually comes from a policy library which is also currently not versioned with no clear way how it will work with the different CRD schemas versions.

Hence we should find a coherent release methodology and convention to be applied across all these components.

- Policy CRD: CRDs are already versioned but need to find a way to link that version to a specific agent version and a policy library
- Policy agent: Should push only to a predetermined tag, it can still push to latest but this shouldn’t be used in any chart
- Policy library: Needs to have tags that corresponds to policy CRD version
- Profiles: Should be aware of which versions to use to retrieve data from policy library and the version of the agent to be used

## Decision

The policy agent will have its own version and it will follow the semantic versioning. It's version will be used for a release tag on the repository and the same tag will be used to push to docker hub and to publish a helm chart.

Policy CRDs will be versioned in a Kubernetes native way and module providing the api structs in Golang should follow the same semantic versioning of the agent repository.

The policy library will have its own version and it will follow the semantic versioning. When the Policy CRDs has new changes the policy library will need to be updated to reflect that change.

Policy Profiles will have their own separate version for the chart version and their app version would be the agent version.

The policy library repository should document in it's release notes which versions of the policy agent are supported.

The agent profile repository should document in it's release notes which versions of the policy agent and the policy library are supported.

### Example

- **Policy Agent** version [v1.0.0](https://github.com/weaveworks/policy-agent/releases/tag/v1.0.0) is compatible with **Policy Library** versions [v0.4.0](https://github.com/weaveworks/policy-library/releases/tag/v0.4.0), [v1.0.0](https://github.com/weaveworks/policy-library/releases/tag/v1.0.0)

- **Policy Agent Profile** version [v0.6.0](https://github.com/weaveworks/profiles-catalog/releases/tag/weave-policy-agent-0.6.0) is compatible with **Policy Agent** version [v1.0.0](https://github.com/weaveworks/policy-agent/releases/tag/v1.0.0) and **Policy Library** versions [v0.4.0](https://github.com/weaveworks/policy-library/releases/tag/v0.4.0), [v1.0.0](https://github.com/weaveworks/policy-library/releases/tag/v1.0.0)


## Consequences

Since the different components don't share the same version. Users need to make sure they are using the correct version of each component which is compatible with other components. That can be achieved by checking the compatibility section in release notes and know which versions are supported.

