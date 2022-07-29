# Pipelines event management 
It aims to document the spike done in the context of cd pipelines about [manage deployment and promotion events](https://github.com/weaveworks/weave-gitops-enterprise/issues/1084)  

## Glossary 

- Pipeline: define application deployment across environments.  
- Pipeline Execution: an instance of a pipeline being executed so application being deployed through environments.
- Deploy/Deployment: an application version being delivered to an environment 
- Promote/Promotion: the action to move an application version from a lower environment to a higher environment in the context of a pipeline.
 For example promote from dev to test or from test to production

## Problem statement 

As version 0.1, we want to be able to follow an application being delivered to different environment according to 
a pipeline definition. Therefore, we need to understand when an application is being delivered to an environment. 

As version 1.0, we want to be able to act as part of the pipeline by promoting an application deployed to an environment 
to the next environment in the pipeline. Therefore we need to define the actions required to promote an application version.

This proposal addresses both 

- to understand when an application is being delivered to an environment.
- to define the actions required to promote an application version.

## Assumptions and Dependencies
- A [pipeline definition](https://github.com/weaveworks/weave-gitops-enterprise/issues/1076) exists. 
- That pipeline definition has as environment dev, test, prod as namesapces within a single cluster
- Flux manages the application deployment via HelmRelease
- We ignore at this stage policy violations as failures

## Understand when an application is being delivered to an environment.

### Hypothesis A: via flux events

Given flux manages the deployment
When an application version is being deployed to environment `dev`
Then I am able to understand 
- `application` that has been deployed
- `application version` that has been deployed
- `environment` that has been deployed to
- `deployment status` on whether has been successful or failure and in case of failure when understand the message
- `other metadata` like deployment duration, etc ...
By looking at the following events 
- <EVENT 1>
- <EVENT 2>
- <EVENT 3>


### Hypothesis B: to be defined


## Recommendation (with limitations) 
- to be made

## Path

## Metadata
- Status: Draft in progress

## References

- [Miro Board](https://miro.com/app/board/uXjVOoWHIfg=/?share_link_id=613790573756)
