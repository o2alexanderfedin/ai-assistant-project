#!/bin/bash
# Create Component field for GitHub Project
# This script creates the Component field and assigns values

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Creating Component field for GitHub Project #$PROJECT_NUM..."

# Create Component field with options
echo "Creating Component field..."
COMPONENTS="Core Agents,MCP,Workflow,Shared Components,External Integration,Testing"
gh projects field-create $PROJECT_NUM --user '@me' --name "Component" --data-type "SINGLE_SELECT" --single-select-options "$COMPONENTS" --format json

echo "✅ Component field created"

# Get field information
echo "Getting field data..."
FIELD_DATA=$(gh api graphql -f query='{
  user(login: "o2alexanderfedin") {
    projectV2(number: '$PROJECT_NUM') {
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

COMPONENT_FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .id')
CORE_AGENTS_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .options[] | select(.name=="Core Agents") | .id')
MCP_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .options[] | select(.name=="MCP") | .id')
WORKFLOW_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .options[] | select(.name=="Workflow") | .id')
SHARED_COMPONENTS_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .options[] | select(.name=="Shared Components") | .id')
EXTERNAL_INTEGRATION_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .options[] | select(.name=="External Integration") | .id')
TESTING_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .options[] | select(.name=="Testing") | .id')

echo "Setting Component field for all items..."

# Get all project items
ITEMS_DATA=$(gh api graphql -f query='{
  user(login: "o2alexanderfedin") {
    projectV2(number: '$PROJECT_NUM') {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              labels(first: 10) {
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

# Process all items
echo "$ITEMS_DATA" | jq -c '.data.user.projectV2.items.nodes[]' | while read -r ITEM; do
  ITEM_ID=$(echo "$ITEM" | jq -r '.id')
  ISSUE_NUM=$(echo "$ITEM" | jq -r '.content.number')
  ISSUE_TITLE=$(echo "$ITEM" | jq -r '.content.title')
  LABELS=$(echo "$ITEM" | jq -r '.content.labels.nodes[].name' 2>/dev/null || echo "")
  
  echo "Processing #$ISSUE_NUM: $ISSUE_TITLE"
  
  # Determine component
  COMPONENT_ID=""
  
  if echo "$LABELS" | grep -q "core-agents"; then
    COMPONENT_ID="$CORE_AGENTS_ID"
    COMPONENT_NAME="Core Agents"
  elif echo "$LABELS" | grep -q "mcp\|communication"; then
    COMPONENT_ID="$MCP_ID"
    COMPONENT_NAME="MCP"
  elif echo "$LABELS" | grep -q "workflow"; then
    COMPONENT_ID="$WORKFLOW_ID"
    COMPONENT_NAME="Workflow"
  elif echo "$ISSUE_TITLE" | grep -q "CI/CD\|GitHub Connector\|Development Environment\|External Integration"; then
    COMPONENT_ID="$EXTERNAL_INTEGRATION_ID"
    COMPONENT_NAME="External Integration"
  elif echo "$ISSUE_TITLE" | grep -q "Testing\|Test"; then
    COMPONENT_ID="$TESTING_ID"
    COMPONENT_NAME="Testing"
  elif echo "$ISSUE_TITLE" | grep -q "Registry\|State Store\|Queue\|History\|Knowledge Base\|Metrics\|Shared Component"; then
    COMPONENT_ID="$SHARED_COMPONENTS_ID"
    COMPONENT_NAME="Shared Components"
  elif echo "$LABELS" | grep -q "documentation\|infrastructure"; then
    COMPONENT_ID="$SHARED_COMPONENTS_ID"
    COMPONENT_NAME="Shared Components"
  fi
  
  # If component determined, set it
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
    ' -F project="PVT_kwHOBJ7Qkc4A5SDb" -F item="$ITEM_ID" -F field="$COMPONENT_FIELD_ID" -F value="$COMPONENT_ID" > /dev/null
    echo "  ✅ Component set"
  else
    echo "  ⚠️ Could not determine component"
  fi
done

echo "🎉 Component field setup complete!"