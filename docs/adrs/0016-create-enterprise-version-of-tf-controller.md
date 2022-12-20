# 16. create the enterprise version of TF-controller

## Status
Proposed

## Context
  - TF-Controller is an open-source project that is maintained by a team of software engineers.
  - Customers are requesting features that should be paid features of TF-Controller.
  - There is confusion over the boundary of work for the open-source version of TF-Controller and its integration as part of our product engineering work.

## Implications
  - The development of an "Enterprise" version of TF-controller could help to address the confusion around the boundary of work for the open-source version and provide a clear separation between paid and unpaid features. This could help to mitigate issues with customers requesting paid features for free.
  - Building the Enterprise version on top of the open-source version and integrating it into the WGE system could be a complex process that requires significant development and testing efforts. This could impact the team's overall productivity and timeline for delivering new features and updates.

## Decisions
  - The team will create an "Enterprise" version of TF-Controller that includes all of the features of the open-source version, as well as additional features developed by our product engineering team (Denim).
  - The Enterprise version will be built on top of the open-source version and integrated into our WGE system as part of the product engineering work.

## Rationale
  - Creating an Enterprise version of TF-Controller will help to address the confusion around the boundary of work for the open-source version and provide a clear separation between paid and unpaid features.
  - Building the Enterprise version on top of the open-source version and integrating it into the WGE system will allow us to leverage the existing codebase and add additional features as needed.
  - This approach will allow us to better meet the needs of our customers and provide a clear value proposition for the paid Enterprise version of TF-Controller.

## Consequences
  - Creating the Enterprise version of TF-Controller will require additional development and testing efforts.
  - It may be necessary to maintain both the open-source and Enterprise versions of TF-Controller. 
    - Maintain the open-source version of TF-controller, following processes similar to those used by the Flux project.
    - Develop and maintain the Enterprise version of TF-controller, as one of the focuses of our product engineering team (Denim).
    - Integrate the Enterprise version into WGE as part of the product engineering work.
  - It's important to consider the potential impact on the open-source community and the overall open-source ecosystem. It may be necessary to clearly communicate the separation between the open-source and Enterprise versions of TF-Controller to avoid any potential confusion or backlash from the community.

## Notes

Maintaining out-of-tree patches and maintaining commits in a branch are both methods of maintaining customizations or modifications to an open-source project. However, there are some key differences between the two approaches:

### Out-of-tree patches:

Out-of-tree patches involve making changes to the source code of an open-source project and then storing those changes in a separate patch file. This allows the changes to be applied to the original project without modifying the original codebase.
Out-of-tree patches can be useful for making small, temporary changes or for testing purposes. They can be easily applied and removed without affecting the original codebase.
However, maintaining out-of-tree patches can be time-consuming, as each patch must be applied and tested separately. Additionally, patches may need to be reapplied or rebased if the original codebase is updated, which can be a labor-intensive process.

### Commits in a branch:

Maintaining customizations or modifications as commits in a branch involves creating a separate branch in the code repository and committing the changes directly to that branch.
This approach allows for a more permanent record of the changes and can make it easier to track and maintain the modifications over time.
However, maintaining a separate branch can be more complex than using out-of-tree patches, as it requires keeping the branch up to date with the upstream project and merging in any changes made to the upstream project. This can be especially challenging if there are frequent updates to the upstream project.

The team will use StGIT to help maintain out-of-tree patches for the project.

StGIT is a well-established patch management tool that is widely used in the open-source community and provides a range of tools for managing and organizing patches.
Using StGIT will allow the team to more efficiently and effectively manage out-of-tree patches, reducing the risk of errors and saving time in the development process.

Maintaining customizations or modifications as commits in a separate branch can be a valid approach to managing changes to an open-source project. However, there are a few potential downsides to consider:
  - **Complexity**: Maintaining a separate branch can be more complex than using out-of-tree patches, as it requires keeping the branch up to date with the upstream project and merging in any changes made to the upstream project. This can be especially challenging if there are frequent updates to the upstream project.
  - **Collaboration**: It may be more difficult for other developers to collaborate on the project if the customizations or modifications are maintained in a separate branch. For example, they may need to switch between branches to access the latest changes or deal with conflicts when merging changes from different branches.
  - **Maintenance**: Maintaining a separate branch can also be more time-consuming in the long term, as it requires more effort to keep the branch up to date with the upstream project and merge in changes. This can impact the team's overall productivity and timeline for delivering new features and updates.

StGIT can simplify the development process that uses out-of-tree patches in a few ways:
  - **Patch management**: StGIT provides a range of tools for managing out-of-tree patches, including the ability to apply, modify, and remove patches as needed. This can make it easier to manage a large number of patches and ensure that they are applied correctly.
  - **Patch organization**: StGIT allows developers to organize patches into a stack, rather than managing them as individual files. This can make it easier to track and manage patches over time, as they can be managed as a single unit.
  - **Patch merging**: StGIT provides tools for merging patches into a single patch or into a branch. This can make it easier to integrate multiple patches into a single unit and simplify the process of applying them to the upstream project.
  - **Patch rebasing**: StGIT allows developers to rebase patches (i.e., apply them to a different version of the upstream project) without applying and reapplying them manually. This can save time and reduce the risk of errors when updating the upstream project.
