# Evolution Patterns

## What This Skill Is For

Use this skill when the assistant is improving itself as a system, not merely completing an external task.

Typical triggers:
- "总结下最近的进步"
- "按这个思路改善你自己"
- "把你的学习进化写成一个 skill"
- "把这些规则结构化"
- "把你的能力整理得更顺手"
- "把这个工作方式沉淀下来"

If the task is specifically about learning from another repository's architecture and applying that structure to the assistant's own workspace, use the more specific architecture-focused skill instead.

## Good Outputs

Strong outputs usually look like one or more of these:

- a clearer operating README
- a status model
- an honesty or verification rule
- a collaboration model
- a reusable checklist
- a lightweight verification entrypoint
- a guardrail
- a reusable skill capturing the new pattern

## Common Refactor Directions

### 1. From implicit memory to explicit structure

Examples:
- move rules from memory into docs
- move repeated checks into scripts
- move hidden assumptions into structured artifacts

### 2. From loose habits to reusable workflow

Examples:
- introduce a checklist
- add a helper script
- formalize reporting structure
- capture a repeated pattern as a skill

### 3. From confidence theater to evidence discipline

Examples:
- add status labels
- distinguish fact from guess
- distinguish generated output from validated output

### 4. From one-off lesson to durable learning

Examples:
- update a skill
- add a note template
- add a policy or guardrail
- create a structured learning artifact

## Suggested Sequence

When the user asks for broad assistant self-improvement, a good sequence is:

1. identify the repeated problem
2. tighten the relevant rule or workflow
3. add a reusable artifact
4. validate the change lightly
5. capture the lesson for future reuse

## What Not To Do

- do not claim the assistant is now "fully productized"
- do not treat presence of docs as proof of stable operations
- do not leave a durable lesson only in chat if it should become an artifact
- do not create machine-readable artifacts unless something will actually use them
