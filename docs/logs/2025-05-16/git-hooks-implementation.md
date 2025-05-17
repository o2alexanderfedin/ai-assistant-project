# Git Hooks Implementation for Process Enforcement

*Date: May 16, 2025*  
*Participants: Developer Agent, DevOps Agent, Architecture Team*

## 📑 Table of Contents
- [Context](#context)
- [Discussion Points](#discussion-points)
- [Implementation Strategy](#implementation-strategy)
- [Hook Implementation Details](#hook-implementation-details)
- [Prompt Engineering Approach](#prompt-engineering-approach)
- [Testing and Validation](#testing-and-validation)
- [Deployment Plan](#deployment-plan)
- [Action Items](#action-items)
- [References](#references)

## Context

The multi-agent system requires mechanisms to ensure consistent process enforcement and guide agent behavior at critical workflow points. Git hooks have been identified as an effective way to **print** contextual prompts that Claude agents can interpret as guidance, while maintaining their autonomy and reasoning capabilities.

## Discussion Points

1. **Process Enforcement Requirements**
   - Need for automated process verification at critical points
   - Guidelines for documentation, testing, and implementation
   - Workflow standardization across agents
   - Pattern recognition and application

2. **Claude Agent Guidance Options**
   - Direct prompting vs. contextual hints
   - Reminder formatting for optimal interpretation
   - Balance between guidance and autonomy
   - Consistent action triggering

3. **Git Hook Selection**
   - Available hook points in the Git workflow
   - Appropriateness of each hook for different guidance
   - Hook chaining for complex processes
   - Hook performance considerations

4. **Implementation Challenges**
   - Cross-platform compatibility
   - Hook distribution and management
   - Versioning of hooks
   - Security considerations

5. **Prompt Engineering**
   - Effective prompt structure for Claude agents
   - Context enrichment techniques
   - Clear directive formatting
   - Balancing detail and brevity

## Implementation Strategy

The team decided to implement a comprehensive Git hook system with these key characteristics:

1. **Centralized Hook Management**: 
   - Hooks maintained in a central repository
   - Distributed via Git's `core.hooksPath` configuration
   - Version-controlled and deployable as a unit

2. **System Reminder Format**:
   - All prompts wrapped in `<system-reminder>` tags
   - Structured format with clear sections
   - Contextual information included
   - Actionable directives provided

3. **Workflow-Aware Behavior**:
   - Hooks adapt based on branch name, task ID, and file changes
   - Different guidance for different workflow stages
   - Integration with GitHub issues for task context
   - Recognition of component boundaries and dependencies

4. **Non-Blocking Design**:
   - Hooks provide guidance but don't block Git operations
   - Zero exit code to allow operations to proceed
   - Minimal performance impact
   - Progressive disclosure of information

## Hook Implementation Details

### Pre-commit Hook

The pre-commit hook will analyze staged changes and provide contextual guidance:

```bash
#!/bin/bash
# pre-commit hook

# Configuration
DOCUMENTATION_REQUIRED=true
TEST_DRIVEN_DEVELOPMENT=true
PATTERN_SUGGESTIONS=true

# Gather context
BRANCH_NAME=$(git branch --show-current)
STAGED_FILES=$(git diff --cached --name-only)
CODE_CHANGES=$(echo "$STAGED_FILES" | grep -v "\.md$" | wc -l)
DOC_CHANGES=$(echo "$STAGED_FILES" | grep "\.md$" | wc -l)
TEST_CHANGES=$(echo "$STAGED_FILES" | grep -E "test|spec" | wc -l)

# Determine task context
if [[ "$BRANCH_NAME" =~ ^task/([0-9]+) ]]; then
  TASK_ID=${BASH_REMATCH[1]}
  if command -v gh &> /dev/null; then
    TASK_INFO=$(gh issue view "$TASK_ID" --json title,body,labels 2>/dev/null)
    TASK_LABELS=$(echo "$TASK_INFO" | jq -r '.labels[].name' 2>/dev/null)
    
    # Check for specific task types
    if [[ "$TASK_LABELS" =~ "documentation" && $DOC_CHANGES -eq 0 ]]; then
      echo "<system-reminder>"
      echo "DOCUMENTATION TASK REMINDER: This task is labeled as documentation, but no documentation files are being changed."
      echo ""
      echo "Expected documentation updates for task #$TASK_ID:"
      echo "- Component documentation in docs/architecture/components/"
      echo "- Interface documentation in docs/architecture/interfaces/"
      echo "- Log entries in docs/logs/$(date +%Y-%m-%d)/"
      echo ""
      echo "Please ensure documentation is updated according to CLAUDE.md guidelines."
      echo "</system-reminder>"
    fi
    
    if [[ "$TASK_LABELS" =~ "feature" && $TEST_CHANGES -eq 0 && "$TEST_DRIVEN_DEVELOPMENT" == "true" ]]; then
      echo "<system-reminder>"
      echo "TDD WORKFLOW REMINDER: This feature task should follow Test-Driven Development practices."
      echo ""
      echo "Remember the TDD workflow:"
      echo "1. Write failing tests first"
      echo "2. Implement minimal code to make tests pass"
      echo "3. Refactor while keeping tests passing"
      echo ""
      echo "No test files are currently being changed in this commit."
      echo "</system-reminder>"
    fi
  fi
fi

# Documentation checks
if [[ $CODE_CHANGES -gt 0 && $DOC_CHANGES -eq 0 && "$DOCUMENTATION_REQUIRED" == "true" ]]; then
  echo "<system-reminder>"
  echo "DOCUMENTATION CHECK: You are committing code changes without updating documentation."
  echo ""
  echo "Please consider whether these changes require updates to:"
  echo "- Component documentation in docs/architecture/components/"
  echo "- Interface documentation in docs/architecture/interfaces/"
  echo "- ADRs for significant decisions in docs/architecture/decisions/"
  echo "- Log entries for implementation details in docs/logs/$(date +%Y-%m-%d)/"
  echo ""
  echo "Remember that all significant changes must be documented according to CLAUDE.md guidelines."
  echo "</system-reminder>"
fi

# Pattern suggestion
if [[ "$PATTERN_SUGGESTIONS" == "true" ]]; then
  for file in $STAGED_FILES; do
    if [[ "$file" =~ \.sh$ ]]; then
      # Shell script patterns
      echo "<system-reminder>"
      echo "SHELL SCRIPT BEST PRACTICES: You're modifying shell scripts. Remember:"
      echo ""
      echo "1. Add proper error handling with 'set -e' or explicit error checks"
      echo "2. Include descriptive usage information in a comment header"
      echo "3. Validate inputs before using them"
      echo "4. Use functions for reusable code blocks"
      echo "5. Follow the logging standards in docs/architecture/decisions/005-git-hooks-process-enforcement.md"
      echo "</system-reminder>"
      break
    elif [[ "$file" =~ component ]]; then
      # Component implementation patterns
      echo "<system-reminder>"
      echo "COMPONENT IMPLEMENTATION PATTERNS: You're working on a component implementation. Consider:"
      echo ""
      echo "1. Follow the component interface contract precisely"
      echo "2. Include proper error handling and logging"
      echo "3. Implement resource cleanup for proper lifecycle management"
      echo "4. Add comprehensive tests for component behavior"
      echo "5. Document any deviations from the component design"
      echo "</system-reminder>"
      break
    fi
  done
fi

exit 0
```

### Commit-msg Hook

The commit-msg hook will enforce commit message standards and task references:

```bash
#!/bin/bash
# commit-msg hook

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat $COMMIT_MSG_FILE)
BRANCH_NAME=$(git branch --show-current)

# Define commit message pattern
COMMIT_PATTERN='^(feat|fix|docs|refactor|test|chore|perf|ci|build|style)(\([a-z-]+\))?: .{3,}(#[0-9]+)?$'

# Check if commit message follows the pattern
if ! [[ "$COMMIT_MSG" =~ $COMMIT_PATTERN ]]; then
  echo "<system-reminder>"
  echo "COMMIT MESSAGE FORMAT: Your commit message doesn't follow the standard format."
  echo ""
  echo "Required format:"
  echo "type(scope): description #task-id"
  echo ""
  echo "Examples:"
  echo "- feat(dev-env): Add Docker container support #42"
  echo "- fix(github): Correct issue mapping logic #17"
  echo "- docs(architecture): Update development environment documentation #23"
  echo ""
  echo "Types: feat, fix, docs, refactor, test, chore, perf, ci, build, style"
  echo "Scope: Optional component or module name in parentheses"
  echo "Description: Clear, concise explanation in present tense"
  echo "Task ID: GitHub issue number with # prefix"
  echo "</system-reminder>"
fi

# Extract task ID from branch name if available
if [[ "$BRANCH_NAME" =~ ^task/([0-9]+) ]]; then
  TASK_ID=${BASH_REMATCH[1]}
  
  # Check if commit message references the task
  if [[ ! "$COMMIT_MSG" =~ "#$TASK_ID" ]]; then
    echo "<system-reminder>"
    echo "TASK REFERENCE REQUIRED: Your commit message should reference Task #$TASK_ID."
    echo ""
    echo "Please include '#$TASK_ID' at the end of your commit message."
    echo "This ensures proper task tracking and documentation linkage."
    echo ""
    echo "Example: 'feat: Add development environment Docker support #$TASK_ID'"
    echo "</system-reminder>"
  fi
fi

exit 0
```

### Post-commit Hook

The post-commit hook will provide workflow guidance based on the committed changes:

```bash
#!/bin/bash
# post-commit hook

LAST_COMMIT_MSG=$(git log -1 --pretty=%B)
CHANGED_FILES=$(git show --name-only --format='' HEAD)

# Determine the commit type from the commit message
COMMIT_TYPE=""
if [[ "$LAST_COMMIT_MSG" =~ ^feat ]]; then
  COMMIT_TYPE="feature"
elif [[ "$LAST_COMMIT_MSG" =~ ^fix ]]; then
  COMMIT_TYPE="bugfix"
elif [[ "$LAST_COMMIT_MSG" =~ ^docs ]]; then
  COMMIT_TYPE="documentation"
elif [[ "$LAST_COMMIT_MSG" =~ ^test ]]; then
  COMMIT_TYPE="testing"
fi

# Provide guidance based on commit type and changed files
case "$COMMIT_TYPE" in
  "feature")
    echo "<system-reminder>"
    echo "FEATURE IMPLEMENTATION: You've committed a feature change."
    echo ""
    echo "Next steps in the feature workflow:"
    echo "1. Ensure tests cover the new functionality"
    echo "2. Update component documentation to reflect the changes"
    echo "3. Add a log entry describing the implementation approach"
    echo "4. Consider whether this feature requires updates to interfaces"
    echo ""
    echo "Remember the principles of SOLID and DRY in your implementation."
    echo "</system-reminder>"
    ;;
  "bugfix")
    echo "<system-reminder>"
    echo "BUG FIX: You've committed a bug fix."
    echo ""
    echo "Bug fix checklist:"
    echo "1. Add tests that would have caught this bug"
    echo "2. Document the root cause in a log entry"
    echo "3. Check for similar bugs elsewhere in the codebase"
    echo "4. Update documentation if the bug was due to unclear usage"
    echo ""
    echo "Consider adding this case to the system's pattern library to prevent similar issues."
    echo "</system-reminder>"
    ;;
  "documentation")
    echo "<system-reminder>"
    echo "DOCUMENTATION UPDATE: You've committed documentation changes."
    echo ""
    echo "Documentation checklist:"
    echo "1. Verify cross-references between documents"
    echo "2. Ensure navigation footers are consistent"
    echo "3. Check for TODOs that can be resolved"
    echo "4. Verify table of contents is accurate"
    echo ""
    echo "Good documentation is essential for system self-improvement and knowledge transfer."
    echo "</system-reminder>"
    ;;
  "testing")
    echo "<system-reminder>"
    echo "TEST CHANGES: You've committed changes to tests."
    echo ""
    echo "Testing checklist:"
    echo "1. Ensure tests are independent and repeatable"
    echo "2. Verify test coverage for edge cases"
    echo "3. Check that test names clearly describe what's being tested"
    echo "4. Consider whether documentation needs updates based on test scenarios"
    echo ""
    echo "Remember that tests serve as executable documentation of system behavior."
    echo "</system-reminder>"
    ;;
esac

exit 0
```

## Prompt Engineering Approach

The team developed specific prompt engineering guidelines to ensure Claude agents interpret the Git hook output effectively:

1. **System Reminder Format**:
   - Wrap all prompts in `<system-reminder>` tags
   - Claude recognizes these tags as special guidance
   - Tags create a clear separation from normal output

2. **Structured Information**:
   - Clear title in all caps to identify the prompt type
   - Brief description of the context
   - Bullet points for specific guidelines
   - Reference links to relevant documentation

3. **Contextual Awareness**:
   - Include task ID, branch name, or file information
   - Reference relevant patterns or processes
   - Adapt guidance based on current workflow stage
   - Provide different guidance for different agent roles

4. **Actionable Directives**:
   - Clearly state expected actions
   - Use imperative language for instructions
   - Provide numbered steps for sequential processes
   - Include examples where appropriate

Example of the prompt structure:

```
<system-reminder>
PROMPT TYPE: Brief description of the context

Detailed explanation with relevant information.

Expected actions:
1. First step to take
2. Second step to take
3. Third step to take

Reference: [Relevant Documentation](path/to/document.md)
</system-reminder>
```

## Testing and Validation

The team established a testing approach for the Git hooks:

1. **Unit Testing**:
   - Test individual hook scripts in isolation
   - Verify correct output for different inputs
   - Check edge cases and error handling

2. **Integration Testing**:
   - Test hooks in a complete Git workflow
   - Verify interaction between different hooks
   - Test with realistic repository contents

3. **Agent Interpretation Testing**:
   - Verify Claude agents correctly interpret the prompts
   - Test different prompt variations for effectiveness
   - Measure impact on agent behavior and output

4. **Performance Testing**:
   - Measure hook execution time
   - Test with large repositories
   - Verify minimal impact on Git operations

## Deployment Plan

The team defined a phased deployment approach:

### Phase 1: Core Process Enforcement
- Deploy basic pre-commit and commit-msg hooks
- Focus on documentation and task reference enforcement
- Collect data on hook effectiveness

### Phase 2: Workflow Guidance
- Add post-commit and pre-push hooks
- Implement context-aware workflow guidance
- Integrate with GitHub for task context

### Phase 3: Advanced Pattern Recognition
- Add pattern suggestions based on file types
- Implement cross-component dependency awareness
- Add performance impact analysis

## Action Items

1. Create ADR for Git hooks process enforcement ✓
2. Implement core pre-commit hook
3. Implement commit-msg hook
4. Implement post-commit hook
5. Create hook distribution mechanism
6. Develop testing framework for hooks
7. Document hook usage and customization
8. Create agent training examples for hook interpretation

## References

- [ADR-005: Git Hooks for Process Enforcement](../../architecture/decisions/005-git-hooks-process-enforcement.md)
- [ADR-003: Agent Task Workflow Standardization](../../architecture/decisions/003-agent-task-workflow.md)
- [GitHub Integration Documentation](../../architecture/interfaces/github-interface.md)
- [Agent Communication Protocol](../../architecture/interfaces/mcp-protocol.md)

---

🧭 **Navigation**
- [Logs Home](../README.md)
- [2025-05-16 Logs](./)