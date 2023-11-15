# Configuration resolution

You want to use:

- cmd.go is the entry point.
- the command is configured -> config.go
- the command is executed -> bootstrap.go

Configuration is on the most important bits in terms of experience and comes from the following sources:

1. existing state 
2. user introduced values via flags
3. user introduced values via interactive questions
4. default values

With the following design principles: 
1. the simplest experience possible for day-0 users.
2. the safest configuration possible for day-0 and day-1 users. For example is safer not to mutate vs mutate. 

We then analysis options and give recommendations. 

## Validation scenarios

### Definitions:

These are defined at the level of the step.

**Actions**

- Create: doesn't exist resources. For example no cluster user auth credentials exists in the cluster.  
- Update: resources already exists. For example cluster user auth credentials exists in the cluster.

**Modes**

- Interactive: user is asked for values through an interactive session.
- Non-interactive: values are introduced via flags.

### Scenarios:


1. `Day-0: create interactive (important)`: A user that haven't bootstrapped yet and wants to bootstrap interactive: `flux bootstrap`
   - ask - the common case where you have little knowledge
2. `Day-0: create non-interactive (less imporant)`:A user that havent bootstrapped yet and wants non-interactive or silent: `flux bootstrap -s`
   - ignore: it is rare cause there is conflicting principle that is unlikely that you would get the journey completed without
     several attempts as there are many flags to introduce. Non-interactive scenarios are more likely for day1 journeys.
3. `Day-1: update non-interactive (important)`: a user that have bootstrapped and wants non-interactive (silent) mode
    - no ask - use input: you dont have previous values and have signaled that you want to use flag values.
    - no ask - use existing: you do have previous values and no new values.
    - no ask - overwrite: you have already previous values and have signaled that you want to use flag values. 
4. `Day-1: update interactive (important)`: a user that have bootstrapped but wants interactive
    - ask suggest previous value: you have previous values no values introduced
    - ask conflict: you have previous values and values introduced
    - no ask - use values: you dont have previous values and values introduced

## Option A: there is no default values configuration layer


### How it looks like 

1. Configuration <- empty
2. Configuration <- discovered from `existing state`
3. Configuration <- f(configuration, `user introduced values`)
    - This would lead for conflicts if existing configuration value is different to user introduce value.
    - We need `overwrite` semantics with conservative behaviour as follows:
        - if flag `overwrite` exists -> user introduced values
        - otherwise
            - if non-interactive -> fail
            - if interactive -> ask the user
    - Values introduced as flag wont be asked as interactive 
4. Configuration <- f(configuration, `interactive values`, `suggested value`): for those values required not yet with value from the previous layer we ask ineractive where the selected value 
   by default is the default value. 
   - Values not-introduced as flag will be asked as interactive session where the user will have a suggested value 
   where `suggestedValue:=f(existing state value, default value)`:
      - if existing state value is not empty -> existing state value
      - otherwise default value

Suggested Values is created during configuration as part of StepInput. The suggested value should ensure it is a safe option. 

From 

```go 
type StepInput struct {
	Name            string
	Msg             string
	StepInformation string
	Type            string
	DefaultValue    any
	Value           any
	Values          []string
	Valuesfn        func(input []StepInput, c *Config) (interface{}, error)
	Enabled         func(input []StepInput, c *Config) bool
	Required        bool
}
```

To 

```go 
type StepInput struct {
	Name            string
	Msg             string
	StepInformation string
	Type            string
	SuggestedValue    any
	Value           any
	Values          []string
	Valuesfn        func(input []StepInput, c *Config) (interface{}, error)
	Enabled         func(input []StepInput, c *Config) bool
	Required        bool
}
```

#### Validation scenarios.

1. `Day-0-Likely`: A user that haven't bootstrapped yet and wants to bootstrap interactive: `flux bootstrap`

- existing state: no
- user introduced values via flags: no
- user introduced values via interactive questions: yes
- default values: yes

The user will be able to complete the configuration journey based on the interactive session

2. `Day-1-Likely`: a user that have bootstrapped and wants to overwrite non-interactive:

- existing state: yes
- user introduced values via flags: no
- user introduced values via interactive questions: yes
- default values: yes

The user will be able to overwrite the existing state cause during the interactive session the suggested value 
will be the existing state values instead of the default.


3. `Day-1-Likely `: a user that have bootstrapped and wants to overwrite interactive:

- existing state: yes
- user introduced values via flags: yes
- user introduced values via interactive questions: yes
- default values: yes

The user will be able:
    - overwrite via flags
    - overwrite via interactive 


### Analysis

## Option B: there is default values configuration layer that is the first configuration layer

### How it looks like

1. Configuration <- empty
2. Configuration <- f(configuration,default values)
3. Configuration <- f(configuration,discovered from existing state)
4. Configuration <- f(configuration,user introduced value)
    - This would lead for conflicts if existing configuration value is different to user introduce value.
    - We need `overwrite` semantics with conservative behaviour as follows:
        - if flag `overwrite` exists -> user introduced values
        - otherwise
            - if non-interactive -> fail
            - if interactive -> ask the user

Interactive questions for those required but empty values:
- not having defaults but required
- not discovered from existing state
- not introduced by user flags

### Analysis

Pro:
- User does not need to introduce values for those wht
Cons:

## Option C: there is default values configuration layer that is the last configuration layer

### How it looks like

1. Configuration <- empty
2. Configuration <- f(configuration,discovered from existing state)
3. Configuration <- f(configuration,user introduced value)
4. Configuration <- f(configuration,default values)

### Analysis


## Recommendation 
