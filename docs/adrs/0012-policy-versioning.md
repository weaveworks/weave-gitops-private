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

Versioning policy library and agent separately by making use of semantic versioning. The idea being that semantic versioning is intuitive and should make it clear which version of policy library requires which version of agent. This also make it possible to update the version of the library or apply patch changes in the agent without having to add redundant data.

Policy CRDs will be versioned in a Kubernetes native way and module providing the api structs in Golang should follow the same semantic versioning of the agent repo.

Agent version will be used for a release tag on the repo and the same tag will be used to push to docker hub and to publish a helm chart. Upgrading major version would be done when major api changes are done and in that case policy library will need to undergo that same update. Meaning that having the same major version indicates that compatibility. API changes should be backward compatible but newer functionalities shouldn’t be expected to work on an older major version.

Policy Profiles will have their own separate version for the chart version and their app version would be the agent version.
