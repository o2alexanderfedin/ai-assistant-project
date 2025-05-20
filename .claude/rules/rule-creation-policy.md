# Rule Creation Policy

## When to Create Rules
Create a new rule under `.claude/rules/` whenever:
1. You solve a non-trivial problem that's likely to recur
2. You find a workaround for a documented limitation
3. You discover a pattern that significantly improves efficiency
4. You encounter undocumented API behaviors or requirements
5. You develop reusable solutions for complex tasks

## Rule Structure
Every rule should follow this format:
```
# Title (Concise description of the problem/solution)

## Problem
Clear statement of the problem being addressed

## Solution
Step-by-step instructions for solving the problem

### Working Example
Code sample or sequence that can be adapted

## Common Errors
Listing of errors you might encounter and how to address them

## Notes
Additional context or caveats

## References
Links to relevant documentation or resources
```

## File Naming Convention
Use kebab-case for file names:
- Descriptive of the problem domain
- Sufficiently specific but not overly long
- Include technology names when relevant
- Examples: `github-parent-child-relationships.md`, `graphql-pagination-handling.md`

## Implementation Process
When you solve a new problem:
1. Document the solution immediately while it's fresh
2. Abstract away specific details to make it generalizable
3. Include working examples with minimal modifications needed
4. Save the rule in `.claude/rules/` with appropriate name
5. Reference related rules if applicable

## Rules Review
Periodically review rules to:
- Update outdated information
- Improve clarity based on further experience
- Consolidate related rules
- Remove rules that are no longer applicable