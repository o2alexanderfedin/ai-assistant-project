# ADR-005: Git Hooks for Process Enforcement

**Date**: May 16, 2025  
**Status**: Accepted  
**Deciders**: Architecture Team  
**Contributors**: Developer Agent, DevOps Agent  

## 📑 Table of Contents
- [Context](#context)
- [Decision](#decision)
- [Implementation Approach](#implementation-approach)
- [Prompt Engineering Strategy](#prompt-engineering-strategy)
- [Hook Types and Responsibilities](#hook-types-and-responsibilities)
- [Rationale](#rationale)
- [Implications](#implications)
- [Related Decisions](#related-decisions)
- [Notes](#notes)

## 📋 Context

The multi-agent system requires consistent enforcement of processes and workflows to ensure reliable operation. While we have documented processes extensively, automatic enforcement mechanisms are needed to:

1. Ensure agents follow standardized task workflows
2. Verify documentation is created and updated with each change
3. Prompt agents with contextual reminders at critical points
4. Enforce patterns and best practices across the system
5. Guide agent behavior without requiring hard-coded rules in agent logic

Git hooks provide a mechanism to execute scripts at specific points in the Git workflow, making them ideal for process enforcement.

## 🚩 Decision

We will implement a comprehensive set of Git hooks that **print** carefully crafted messages that Claude agents will interpret as contextual prompts. These hooks will serve multiple purposes:

1. **Process Enforcement**: Ensure agents follow documented processes
2. **Documentation Reminders**: Verify documentation is created and updated
3. **Context Enhancement**: Provide relevant context for current tasks
4. **Pattern Suggestions**: Recommend appropriate patterns for specific situations
5. **Task Guidance**: Guide agents through complex workflows

The hooks will be implemented as shell scripts in a central repository that all agent repositories can reference, ensuring consistent process enforcement across the system.

## 💻 Implementation Approach

### Hook Distribution System

The Git hooks will be distributed using a central hook template repository that each agent repository links to using Git's `core.hooksPath` configuration. This ensures:

1. Consistent hook behavior across all repositories
2. Central management of hook logic
3. Version control of hooks
4. Easy updates to all agents

```bash
#!/bin/bash
# setup-hooks.sh - Script to configure Git hooks for an agent repository

# Set the hooks path to the central hooks repository
git config core.hooksPath "/shared/git-hooks"

# Create symbolic link to ensure hooks are executable
ln -sf "/shared/git-hooks/pre-commit" ".git/hooks/pre-commit"
ln -sf "/shared/git-hooks/commit-msg" ".git/hooks/commit-msg"
ln -sf "/shared/git-hooks/post-commit" ".git/hooks/post-commit"
ln -sf "/shared/git-hooks/pre-push" ".git/hooks/pre-push"

echo "Git hooks configured successfully."
```

### Hook Structure

Each hook will follow a standard structure with:

1. Config section for customization
2. Context gathering logic
3. Rule evaluation
4. Prompt generation
5. Output formatting for Claude interpretation

```bash
#!/bin/bash
# Example hook structure

# Configuration
DOCUMENTATION_REQUIRED=true
PROMPT_LEVEL="detailed"  # "minimal", "standard", "detailed"

# Context gathering
TASK_ID=$(git config --get task.id)
BRANCH_NAME=$(git branch --show-current)
CHANGED_FILES=$(git diff --cached --name-only)

# Rule evaluation
if [[ "$BRANCH_NAME" =~ ^task/([0-9]+) ]]; then
  TASK_ID=${BASH_REMATCH[1]}
  TASK_DETAILS=$(gh issue view "$TASK_ID" --json title,body,labels)
  
  # Check for documentation requirements
  if [[ "$DOCUMENTATION_REQUIRED" == "true" && ! "$CHANGED_FILES" =~ .*\.md$ ]]; then
    # Print reminder that Claude will interpret as a prompt
    echo "<system-reminder>"
    echo "DOCUMENTATION UPDATE REQUIRED: This task requires documentation updates."
    echo "Remember to follow the standard documentation process:"
    echo "1. Update relevant architecture documents in docs/architecture/"
    echo "2. Add log entry in docs/logs/$(date +%Y-%m-%d)/"
    echo "3. Ensure cross-references are maintained"
    echo "</system-reminder>"
  fi
fi

# Always allow the git operation to proceed
exit 0
```

## 📝 Prompt Engineering Strategy

The Git hooks will use a careful prompt engineering strategy to ensure Claude agents interpret the printed messages appropriately:

1. **System Reminder Format**: All prompts will be wrapped in `<system-reminder>` tags to indicate they should be interpreted as system guidance
2. **Contextual Awareness**: Include relevant context about the current task, branch, and changes
3. **Clear Directives**: Use concise, actionable directives that agents can follow
4. **Process References**: Include references to documented processes
5. **Layered Information**: Provide essential information first, followed by details

Example of a well-crafted prompt:

```
<system-reminder>
TASK WORKFLOW REMINDER: You are working on a development task that requires following the Test-Driven Development workflow.

Current phase: Implementation
Expected actions:
1. Ensure tests are written and failing
2. Implement the minimal code to make tests pass
3. Document your implementation approach in docs/logs/2025-05-16/

Reference documentation: docs/architecture/decisions/003-agent-task-workflow.md
</system-reminder>
```

## 🔄 Hook Types and Responsibilities

### Pre-commit Hook

Responsibilities:
- Verify documentation updates for code changes
- Check for test coverage in TDD workflow
- Ensure proper task references
- Identify potential pattern applications

**Example pre-commit prompt for documentation updates:**

```bash
#!/bin/bash
# pre-commit hook

CHANGED_FILES=$(git diff --cached --name-only)
CODE_CHANGES=$(git diff --cached --name-only | grep -v "\.md$" | wc -l)
DOC_CHANGES=$(git diff --cached --name-only | grep "\.md$" | wc -l)

# Check if code is being changed without documentation
if [[ $CODE_CHANGES -gt 0 && $DOC_CHANGES -eq 0 ]]; then
  echo "<system-reminder>"
  echo "DOCUMENTATION CHECK: You are committing code changes without updating documentation."
  echo ""
  echo "Please consider whether these changes require updates to:"
  echo "- Component documentation (docs/architecture/components/)"
  echo "- Interface documentation (docs/architecture/interfaces/)"
  echo "- ADRs for significant decisions (docs/architecture/decisions/)"
  echo "- Log entries for implementation details (docs/logs/$(date +%Y-%m-%d)/)"
  echo ""
  echo "Remember that all significant changes must be documented according to CLAUDE.md guidelines."
  echo "</system-reminder>"
fi

exit 0
```

### Commit-msg Hook

Responsibilities:
- Enforce standardized commit message format
- Ensure task references in commit messages
- Verify appropriate issue linking

**Example commit-msg prompt for task references:**

```bash
#!/bin/bash
# commit-msg hook

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat $COMMIT_MSG_FILE)
BRANCH_NAME=$(git branch --show-current)

# Extract task ID from branch name if available
if [[ "$BRANCH_NAME" =~ ^task/([0-9]+) ]]; then
  TASK_ID=${BASH_REMATCH[1]}
  
  # Check if commit message references the task
  if [[ ! "$COMMIT_MSG" =~ "#$TASK_ID" ]]; then
    echo "<system-reminder>"
    echo "TASK REFERENCE REQUIRED: Your commit message should reference Task #$TASK_ID."
    echo ""
    echo "Please follow the commit message format:"
    echo "feat/fix/docs/refactor: Short description #$TASK_ID"
    echo ""
    echo "Example: 'feat: Add development environment Docker support #$TASK_ID'"
    echo ""
    echo "This ensures proper task tracking and documentation linkage."
    echo "</system-reminder>"
  fi
fi

exit 0
```

### Post-commit Hook

Responsibilities:
- Generate documentation update reminders
- Suggest next steps in workflow
- Provide context for the committed changes

**Example post-commit prompt for workflow guidance:**

```bash
#!/bin/bash
# post-commit hook

LAST_COMMIT_MSG=$(git log -1 --pretty=%B)
CHANGED_FILES=$(git show --name-only --format='' HEAD)

# Determine the type of changes made
if [[ "$CHANGED_FILES" =~ test ]]; then
  # Tests were added or modified
  echo "<system-reminder>"
  echo "TEST CHANGES DETECTED: You've committed changes to tests."
  echo ""
  echo "Next steps in the TDD workflow:"
  echo "1. Ensure tests are failing for the right reasons"
  echo "2. Implement the minimal code to make tests pass"
  echo "3. Refactor while keeping tests passing"
  echo "4. Document your implementation approach"
  echo ""
  echo "Remember to follow the agent task workflow as documented in docs/architecture/decisions/003-agent-task-workflow.md"
  echo "</system-reminder>"
elif [[ "$CHANGED_FILES" =~ \.md$ ]]; then
  # Documentation was updated
  echo "<system-reminder>"
  echo "DOCUMENTATION UPDATED: You've committed changes to documentation."
  echo ""
  echo "Remember to:"
  echo "1. Verify cross-references between documents"
  echo "2. Ensure navigation footers are consistent"
  echo "3. Update any related README.md files"
  echo "4. Check for any TODOs that can be resolved"
  echo ""
  echo "Good documentation is essential for system self-improvement and knowledge transfer."
  echo "</system-reminder>"
fi

exit 0
```

### Pre-push Hook

Responsibilities:
- Verify all tests pass before pushing
- Check for incomplete TODOs
- Ensure documentation completeness
- Suggest workflow improvements

**Example pre-push prompt for final checks:**

```bash
#!/bin/bash
# pre-push hook

BRANCH_NAME=$(git branch --show-current)
COMMITS_TO_PUSH=$(git log @{u}..HEAD --oneline)
NUM_COMMITS=$(echo "$COMMITS_TO_PUSH" | wc -l)

echo "<system-reminder>"
echo "PUSH PREPARATION: You're about to push $NUM_COMMITS commits to $BRANCH_NAME."
echo ""
echo "Final checklist before pushing:"
echo "1. All tests are passing"
echo "2. Documentation is updated"
echo "3. Code follows established patterns"
echo "4. All TODOs are addressed or documented"
echo ""
echo "This ensures your changes maintain system quality and consistency."
echo "</system-reminder>"

exit 0
```

## 💡 Rationale

Using Git hooks to print system reminders for Claude agents provides several advantages:

1. **Non-intrusive Guidance**: Provides direction without limiting agent autonomy
2. **Contextual Awareness**: Delivers prompts at the most relevant moments in the workflow
3. **Process Integration**: Embeds process enforcement in standard Git workflows
4. **Consistency**: Ensures all agents receive the same guidance for similar situations
5. **Extensibility**: Easily updated to incorporate new processes or patterns
6. **Minimal Overhead**: Simple implementation requiring only shell scripts
7. **Flexible Control**: Can be adjusted based on repository, branch, or task context

The approach leverages Claude's ability to interpret system reminders as guidance without requiring changes to the agent's core logic or capabilities.

## 🔄 Implications

### Positive
- Processes will be consistently enforced across all agent activities
- Agents will receive contextual guidance at critical workflow points
- Documentation quality and completeness will improve
- Pattern recognition and application will be enhanced
- System self-improvement capability will be strengthened

### Negative
- Git operations may display additional output that non-Claude users might find confusing
- Hooks require maintenance as processes evolve
- Complex hook logic could impact performance of Git operations
- Over-reliance on hooks could create dependency on the mechanism

### Neutral
- Agents will need to be configured to interpret the system reminders appropriately
- System administrators will need to manage the hook distribution system
- Hook output will need to be formatted consistently for Claude interpretation

## 🔗 Related Decisions

- [ADR-001: Agent Communication Protocol](./001-agent-communication-protocol.md)
- [ADR-002: GitHub Integration Strategy](./002-github-integration-strategy.md)
- [ADR-003: Agent Task Workflow Standardization](./003-agent-task-workflow.md)
- [ADR-004: Development Environment Strategy](./004-development-environment-strategy.md)

## 📝 Notes

### Implementation Phases

1. **Phase 1 - Core Hooks**:
   - Basic process enforcement hooks
   - Documentation verification
   - Task workflow guidance

2. **Phase 2 - Advanced Context**:
   - Pattern recognition and suggestion
   - Cross-component dependency awareness
   - Performance impact analysis

3. **Phase 3 - Adaptive Behavior**:
   - Learning from past agent responses
   - Customization based on agent specialization
   - Dynamic prompt adjustment

### Security Considerations

1. **Sanitization**: All dynamic content in prompts must be properly sanitized
2. **Privilege Management**: Hooks must operate with appropriate permissions
3. **Privacy**: Sensitive information should not be included in prompts
4. **Validation**: Input from external systems must be validated

### Performance Optimization

1. **Caching**: Cache expensive operations to improve hook performance
2. **Selective Execution**: Only run relevant hooks based on context
3. **Async Operations**: Use background processes for non-blocking checks
4. **Timeout Limits**: Ensure hooks complete within reasonable timeframes

---

🧭 **Navigation**
- [Architecture Decisions Home](./README.md)
- [Architecture Home](../README.md)
- [Previous: Development Environment Strategy](./004-development-environment-strategy.md)