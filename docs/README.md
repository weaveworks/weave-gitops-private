# Design Guidelines

## Why 

Design is about exploring unknowns, define solutions and bringing alignment to address them. Different teams approaches design 
in a different way. This is perfectly fine and encouraged to continue exploring the path that better allows you 
to achieve the outcomes. 

However, doing it effectively, efficiently and within a group of stakeholders isn't trivial. There is 
a space to provide some support to the organisation on how to do that. 

## What

Provide simple guidelines about designing.

## How

We suggest to follow a simple design cycle in three stages

1. early design for a being able to articulate a direction
2. direction has been taken and recorded 
3. complete understanding /design and implementation

## Stage 1: early design for a being able to articulate a direction

The aim of this stage is to do an early discovery of the problem and alternatives. 
The goal is to provide just enough information for the stakeholders to set a direction of travel for the solution to the problem.
At this stage, it is not expected to have all unknowns addressed not all the risks managed. It is to gain enough knowledge
at fast speed to understand more major impediment that would make not feasible a solution or solutions.

It could take different formats but we suggest to follow [ADRs](/Users/enekofb/projects/github.com/weaveworks/weave-gitops-private/docs/adrs)
to help document this stage.  If you follow this format, 
the recommendation is to have filled the `Context` section articulating 
- the problem statement
- the early discovered solutions with initial tradeoffs

In terms of time to spend on this section. It would depend on the dynamics, but a good rule of thumb for Stage 1 and Stage 2 
could be to spend one week. If you are spending more, might be time to look at reducing the scope, looking at your 
stakeholder structure etc ... 

An example of this stage could be seen XYX

## Stage 2: direction has been taken and recorded

Once you have a solution landscape is time to assume tradeoffs and record the decission completing the ADR. 
This stage is for the different stakeholders to meet and align on what is the best direction to take 
and to record the tradeoffs assumed. 

Regarding stakeholders, not everyone is a stakeholder in every decision, nor all stakeholders are playing an equal role. 
Use a mechanism to understand this structure to help you manage this alignment, for example [RACI](https://en.wikipedia.org/wiki/Responsibility_assignment_matrix#Key_responsibility_roles_in_RACI_model).

If you are using ADRs, this section should give you to a complete ADR with Decision and Consequences being completed. 

## Stage 3: complete understanding /design and implementation

At this stage we have the solution we think would better satisfy the problem statement. Now it is time 
to kickoff delivery and in depth design.

This stage is mostly for the team responsible / owner of the feature to align on finer details like 
- how the architecture looks like in terms of components 
- how the interactions in terms of sequence diagrams looks like
- how the apis and messages between components
- what are the database schemas to use, etc ...
