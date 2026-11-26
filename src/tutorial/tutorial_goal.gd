class_name TutorialGoal
extends Resource
## One goal of an action hint: the hint ends once every goal's fact has reached its amount.

## Fact names understood by TutorialHost.
const FACT_MOVED_METERS: StringName = &"moved_meters"
const FACT_TURNED_DEGREES: StringName = &"turned_degrees"
const FACT_SUBSTANCE_HELD_SECONDS: StringName = &"substance_held_seconds"
const FACT_SHOTS_FIRED: StringName = &"shots_fired"

@export var fact: StringName = &""
## Substance kind for substance_held_seconds ("coffee" / "cigarette"); empty otherwise.
@export var substance: StringName = &""
@export var amount: float = 1.0
