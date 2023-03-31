# Design Guidelines

## Why 

Design is about exploring unknowns, define solutions and bringing alignment along the way. 
Doing it effectively, efficiently and within a group of stakeholders isn't trivial. There is 
a space to some support to the organisation on how to do that. 

## What

Provide simple guidelines about designing.

## How

A simple design cycle in three stages

1. Early design for a being able to articulate a direction
2. Decide your direction of travel and tradeoffs. Record it. 
3. Complete understanding /design and implementation

### Stage 1: early design for a being able to articulate a direction

The aim of this stage is to do an early discovery of the problem and alternatives. 
The goal is to provide just enough information for the stakeholders to set a direction of travel for the solution to the problem.
At this stage, it is not expected to have all unknowns addressed not all the risks managed. It is to gain enough knowledge
at fast speed to understand major impediments that would make not feasible a solution or solutions.

It could take different formats, but we suggest to follow [ADRs](./adrs/0001-record-architecture-decisions.md)
to help document this stage.  If you follow this format, 
the recommendation is to have filled the `Context` section articulating 
- the problem statement
- the early discovered solutions with initial tradeoffs

In terms of time to spend on this section. It would depend on the dynamics, but a good rule of thumb for Stage 1 and Stage 2 
could be to spend one week. If you are spending more, might be time to look at reducing the scope, looking at your 
stakeholder structure etc ... 

This discovery should have made you [discover the landscape](./rfcs/template.md#landscape-consideration) 

An example of this stage could be seen <TODO add eaxmple>

### Stage 2: direction has been taken and recorded

Once you have a solution landscape is time to assume tradeoffs and record the decision completing the ADR. 
This stage is for the different stakeholders to meet and align on what is the best direction to take 
and to record the tradeoffs assumed. 

Regarding stakeholders, not everyone is a stakeholder in every decision, nor all stakeholders are playing an equal role. 
Use a mechanism to understand this structure to help you manage this alignment, for example [RACI](https://en.wikipedia.org/wiki/Responsibility_assignment_matrix#Key_responsibility_roles_in_RACI_model).

If you are using ADRs, this section should give you to a complete ADR with Decision and Consequences being completed. 

### Stage 3: complete understanding design and implementation

At this stage we have a direction of travel that we think will best address the problem. Now it is time 
to kickoff delivery and iterate design in depth. 

- Design in depth the parts of the solution which are still carrying major unknowns and risks.
- Delivery for those parts of the solution that deliver values with the current understanding and won't 
require major rework from the design in depth.

This stage is mostly for stakeholders with direct responsibility to align on finer details like: 
- how the architecture looks like in terms of components. Use [Architecture Documentation](https://www.notion.so/weaveworks/Architecture-d5da0449d3eb400cbad3591218e9a3e0).
- how do the domain and interactions look like in terms of diagrams. Domain models and sequence diagrams are welcome. 
- how the apis and messages between components. Check [this ADR](https://github.com/weaveworks/weave-gitops/blob/main/doc/adr/0002-api-definitions-grpc.md)
- what are the database schemas to use, etc ...

For the design doc, it could take different formats, but we suggest to leverage existing [RFC](./rfcs/template.md) template. 

## FAQ

### Design for my team works fine, should I stick to the guidelines?

Different teams approach design in a different way. This is perfectly fine and encouraged to continue exploring
the path that better allows you to achieve the outcomes. Consider whether there are pieces of the guidelines
that you could leverage. For example, it is common to have something tha work for the team but does not
acknowledge a wider group of stakeholders. If that is your case, you could adopt only this part to your direction of travel.

### Could you use these guidelines for retroactive decisions or designs?

The guidelines are thought for mainly discovering new problems, bring alignment along the way and document. 
A retrospective action definitely makes sense whether any of the previous outcomes (potentially the two later) are
not achieved with the current status quo. 

### Where in the process do you suggest to spike?

Spikes are for transforming unknowns into knowns (with a degree confidence). Given that, it is expected
that in order to set a direction of travel (stage 1) and for achieving in depth understanding (stage 3), spikes will
be required. 

### Are stakeholders between stage 1 and stage 3 different?
Most likely: you would find that a high level direction would be interested to be set by a wider group 
of stakeholders so stage 1 might be broader. Stage 3 might be smaller the circle of responsibility.