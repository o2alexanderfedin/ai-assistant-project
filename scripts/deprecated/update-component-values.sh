#!/bin/bash
# Update Component field values for GitHub Project issues
# This script identifies and sets appropriate component values based on labels and issue content

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Updating Component field values for GitHub Project #$PROJECT_NUM..."

# Get project and field information
echo "Getting project and field information..."
FIELD_DATA=$(gh api graphql -f query='{
  user(login: "o2alexanderfedin") {
    projectV2(number: '$PROJECT_NUM') {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}')

# Extract project ID and field IDs
echo "Processing field data..."
PROJECT_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.id')
COMPONENT_FIELD_DATA=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component")')
COMPONENT_FIELD_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.id')

# Make sure Component field exists
if [ -z "$COMPONENT_FIELD_ID" ]; then
  echo "❌ Error: Component field not found in project #$PROJECT_NUM"
  echo "Please run create-component-field.sh first to create the field"
  exit 1
fi

# Extract component option IDs
CORE_AGENTS_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options[] | select(.name=="Core Agents") | .id')
MCP_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options[] | select(.name=="MCP") | .id')
WORKFLOW_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options[] | select(.name=="Workflow") | .id')
SHARED_COMPONENTS_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options[] | select(.name=="Shared Components") | .id')
EXTERNAL_INTEGRATION_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options[] | select(.name=="External Integration") | .id')
TESTING_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options[] | select(.name=="Testing") | .id')

# Verify all option IDs were found
if [ -z "$CORE_AGENTS_ID" ] || [ -z "$MCP_ID" ] || [ -z "$WORKFLOW_ID" ] || [ -z "$SHARED_COMPONENTS_ID" ] || [ -z "$EXTERNAL_INTEGRATION_ID" ] || [ -z "$TESTING_ID" ]; then
  echo "❌ Error: One or more component options not found"
  echo "Please check that the Component field has all required options"
  exit 1
fi

echo "Project ID: $PROJECT_ID"
echo "Component field ID: $COMPONENT_FIELD_ID"

# Get all issues in the project
echo "Getting all issues from the project..."
ITEMS_DATA=$(gh api graphql -f query='{
  user(login: "o2alexanderfedin") {
    projectV2(number: '$PROJECT_NUM') {
      items(first: 100) {
        nodes {
          id
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field {
                  ... on ProjectV2SingleSelectField {
                    name
                  }
                }
                name
              }
            }
          }
          content {
            ... on Issue {
              id
              number
              title
              body
              labels(first: 20) {
                nodes {
                  name
                }
              }
            }
          }
        }
      }
    }
  }
}')

# Initialize counters
TOTAL_ITEMS=0
UPDATED_ITEMS=0
ALREADY_SET_ITEMS=0
SKIPPED_ITEMS=0

# Process each item
echo "$ITEMS_DATA" | jq -c '.data.user.projectV2.items.nodes[]' | while read -r ITEM; do
  ITEM_ID=$(echo "$ITEM" | jq -r '.id')
  ISSUE_NUM=$(echo "$ITEM" | jq -r '.content.number')
  ISSUE_TITLE=$(echo "$ITEM" | jq -r '.content.title')
  ISSUE_BODY=$(echo "$ITEM" | jq -r '.content.body // ""')
  LABELS=$(echo "$ITEM" | jq -r '.content.labels.nodes[].name' 2>/dev/null || echo "")
  
  # Check if component is already set
  CURRENT_COMPONENT=$(echo "$ITEM" | jq -r '.fieldValues.nodes[] | select(.field.name=="Component") | .name' 2>/dev/null || echo "")
  
  echo "Processing #$ISSUE_NUM: $ISSUE_TITLE"
  TOTAL_ITEMS=$((TOTAL_ITEMS + 1))
  
  if [ ! -z "$CURRENT_COMPONENT" ]; then
    echo "  ℹ️ Component already set to: $CURRENT_COMPONENT"
    ALREADY_SET_ITEMS=$((ALREADY_SET_ITEMS + 1))
    continue
  fi
  
  # Determine appropriate component
  COMPONENT_ID=""
  COMPONENT_NAME=""
  
  # Check labels first
  if echo "$LABELS" | grep -qi "core-agents\|developer-agent\|implementer-agent\|reviewer-agent\|tester-agent\|documentation-agent\|devops-agent"; then
    COMPONENT_ID="$CORE_AGENTS_ID"
    COMPONENT_NAME="Core Agents"
  elif echo "$LABELS" | grep -qi "mcp\|protocol\|communication"; then
    COMPONENT_ID="$MCP_ID"
    COMPONENT_NAME="MCP"
  elif echo "$LABELS" | grep -qi "workflow\|orchestration\|task-workflow"; then
    COMPONENT_ID="$WORKFLOW_ID"
    COMPONENT_NAME="Workflow"
  elif echo "$LABELS" | grep -qi "integration\|external\|github\|ci/cd\|cicd"; then
    COMPONENT_ID="$EXTERNAL_INTEGRATION_ID"
    COMPONENT_NAME="External Integration"
  elif echo "$LABELS" | grep -qi "testing\|test\|tdd"; then
    COMPONENT_ID="$TESTING_ID"
    COMPONENT_NAME="Testing"
  elif echo "$LABELS" | grep -qi "shared\|components\|registry\|store\|queue\|knowledge-base\|metrics"; then
    COMPONENT_ID="$SHARED_COMPONENTS_ID"
    COMPONENT_NAME="Shared Components"
  fi
  
  # If labels didn't determine component, check title and body
  if [ -z "$COMPONENT_ID" ]; then
    if echo "$ISSUE_TITLE $ISSUE_BODY" | grep -qi "developer agent\|implementer agent\|reviewer agent\|tester agent\|documentation agent\|devops agent"; then
      COMPONENT_ID="$CORE_AGENTS_ID"
      COMPONENT_NAME="Core Agents"
    elif echo "$ISSUE_TITLE $ISSUE_BODY" | grep -qi "mcp\|protocol\|communication"; then
      COMPONENT_ID="$MCP_ID"
      COMPONENT_NAME="MCP"
    elif echo "$ISSUE_TITLE $ISSUE_BODY" | grep -qi "workflow\|orchestration\|task \(flow\|lifecycle\)"; then
      COMPONENT_ID="$WORKFLOW_ID"
      COMPONENT_NAME="Workflow"
    elif echo "$ISSUE_TITLE $ISSUE_BODY" | grep -qi "github\|ci/cd\|cicd\|continuous integration\|development environment\|external"; then
      COMPONENT_ID="$EXTERNAL_INTEGRATION_ID"
      COMPONENT_NAME="External Integration"
    elif echo "$ISSUE_TITLE $ISSUE_BODY" | grep -qi "test\|tdd"; then
      COMPONENT_ID="$TESTING_ID"
      COMPONENT_NAME="Testing"
    elif echo "$ISSUE_TITLE $ISSUE_BODY" | grep -qi "registry\|state store\|task queue\|knowledge base\|history\|metrics\|shared component"; then
      COMPONENT_ID="$SHARED_COMPONENTS_ID"
      COMPONENT_NAME="Shared Components"
    fi
  fi
  
  # Set component if determined
  if [ ! -z "$COMPONENT_ID" ]; then
    echo "  Setting Component to $COMPONENT_NAME"
    gh api graphql -f query='
      mutation($project:ID!, $item:ID!, $field:ID!, $value:String!) {
        updateProjectV2ItemFieldValue(
          input: {
            projectId: $project
            itemId: $item
            fieldId: $field
            value: { 
              singleSelectOptionId: $value
            }
          }
        ) {
          clientMutationId
        }
      }
    ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$COMPONENT_FIELD_ID -F value=$COMPONENT_ID > /dev/null
    UPDATED_ITEMS=$((UPDATED_ITEMS + 1))
    echo "  ✅ Component set successfully"
  else
    echo "  ⚠️ Could not determine appropriate component"
    SKIPPED_ITEMS=$((SKIPPED_ITEMS + 1))
  fi
done

# Print summary
echo ""
echo "🎉 Component update complete!"
echo "Total items processed: $TOTAL_ITEMS"
echo "Items already set: $ALREADY_SET_ITEMS"
echo "Items updated: $UPDATED_ITEMS"
echo "Items skipped (no component determined): $SKIPPED_ITEMS"