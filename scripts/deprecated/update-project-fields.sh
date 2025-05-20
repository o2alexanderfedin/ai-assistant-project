#!/bin/bash
# Update GitHub Project fields for all items
# This script uses GraphQL to update fields directly

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Updating fields for GitHub Project #$PROJECT_NUM..."

# Get project ID
echo "Getting project information..."
PROJECT_DATA=$(gh api graphql -f query='{
  user(login: "o2alexanderfedin") {
    projectV2(number: '$PROJECT_NUM') {
      id
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
          }
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

echo "Processing field data..."
PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.id')

# Extract field IDs
TYPE_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Type")')
TYPE_FIELD_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.id')
TYPE_EPIC_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.options[] | select(.name=="Epic") | .id')
TYPE_STORY_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.options[] | select(.name=="User Story") | .id')

PRIORITY_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Priority")')
PRIORITY_FIELD_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.id')
PRIORITY_HIGH_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.options[] | select(.name=="High") | .id')
PRIORITY_MEDIUM_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.options[] | select(.name=="Medium") | .id')
PRIORITY_LOW_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.options[] | select(.name=="Low") | .id')

POINTS_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Story Points") | .id')

echo "Project ID: $PROJECT_ID"
echo "Type field ID: $TYPE_FIELD_ID"
echo "Priority field ID: $PRIORITY_FIELD_ID"
echo "Story Points field ID: $POINTS_FIELD_ID"

# Get all epics
EPICS=$(gh issue list --label epic --json number --repo "$REPO" | jq -r '.[].number')
echo "Found epics: $EPICS"

# Get all user stories
USER_STORIES=$(gh issue list --label user-story --json number --repo "$REPO" | jq -r '.[].number')
echo "Found user stories: $USER_STORIES"

# Process epics
for EPIC_NUM in $EPICS; do
  echo "Processing epic #$EPIC_NUM..."
  
  # Get epic labels
  LABELS=$(gh issue view $EPIC_NUM --json labels --repo "$REPO" | jq -r '.labels[].name')
  
  # Get item ID in project
  ITEM_DATA=$(gh api graphql -f query='{
    user(login: "o2alexanderfedin") {
      projectV2(number: '$PROJECT_NUM') {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue {
                number
              }
            }
          }
        }
      }
    }
  }')
  
  ITEM_ID=$(echo "$ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number==$EPIC_NUM) | .id")
  
  if [ -z "$ITEM_ID" ]; then
    echo "  ⚠️ Epic #$EPIC_NUM not found in project, skipping"
    continue
  fi
  
  # Set Type field to Epic
  echo "  Setting Type to Epic"
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
  ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$TYPE_FIELD_ID -F value=$TYPE_EPIC_ID > /dev/null
  
  # Set Priority field
  PRIORITY_OPTION_ID=""
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY_OPTION_ID="$PRIORITY_HIGH_ID"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY_OPTION_ID="$PRIORITY_HIGH_ID"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY_OPTION_ID="$PRIORITY_MEDIUM_ID"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY_OPTION_ID="$PRIORITY_LOW_ID"
  fi
  
  if [ ! -z "$PRIORITY_OPTION_ID" ]; then
    echo "  Setting Priority field"
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
    ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$PRIORITY_FIELD_ID -F value=$PRIORITY_OPTION_ID > /dev/null
  fi
  
  echo "  ✅ Updated epic #$EPIC_NUM"
done

# Process user stories
for STORY_NUM in $USER_STORIES; do
  echo "Processing user story #$STORY_NUM..."
  
  # Get user story labels and body
  STORY_DATA=$(gh issue view $STORY_NUM --json labels,body --repo "$REPO")
  LABELS=$(echo "$STORY_DATA" | jq -r '.labels[].name')
  BODY=$(echo "$STORY_DATA" | jq -r '.body')
  
  # Get item ID in project
  ITEM_DATA=$(gh api graphql -f query='{
    user(login: "o2alexanderfedin") {
      projectV2(number: '$PROJECT_NUM') {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue {
                number
              }
            }
          }
        }
      }
    }
  }')
  
  ITEM_ID=$(echo "$ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number==$STORY_NUM) | .id")
  
  if [ -z "$ITEM_ID" ]; then
    echo "  ⚠️ User story #$STORY_NUM not found in project, skipping"
    continue
  fi
  
  # Set Type field to User Story
  echo "  Setting Type to User Story"
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
  ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$TYPE_FIELD_ID -F value=$TYPE_STORY_ID > /dev/null
  
  # Set Priority field
  PRIORITY_OPTION_ID=""
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY_OPTION_ID="$PRIORITY_HIGH_ID"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY_OPTION_ID="$PRIORITY_HIGH_ID"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY_OPTION_ID="$PRIORITY_MEDIUM_ID"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY_OPTION_ID="$PRIORITY_LOW_ID"
  fi
  
  if [ ! -z "$PRIORITY_OPTION_ID" ]; then
    echo "  Setting Priority field"
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
    ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$PRIORITY_FIELD_ID -F value=$PRIORITY_OPTION_ID > /dev/null
  fi
  
  # Set Story Points field
  POINTS=""
  for LABEL in $LABELS; do
    if [[ "$LABEL" == points:* ]]; then
      POINTS="${LABEL#points:}"
    fi
  done
  
  if [ ! -z "$POINTS" ] && [[ "$POINTS" =~ ^[0-9]+$ ]]; then
    echo "  Setting Story Points to $POINTS"
    gh api graphql -f query='
      mutation($project:ID!, $item:ID!, $field:ID!, $value:Float!) {
        updateProjectV2ItemFieldValue(
          input: {
            projectId: $project
            itemId: $item
            fieldId: $field
            value: { 
              number: $value
            }
          }
        ) {
          clientMutationId
        }
      }
    ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$POINTS_FIELD_ID -F value=$POINTS > /dev/null
  fi
  
  echo "  ✅ Updated user story #$STORY_NUM"
done

echo "🎉 Field update complete!"
echo ""
echo "Fields updated:"
echo "- Type (Epic or User Story based on labels)"
echo "- Priority (High, Medium, Low based on priority labels)"
echo "- Story Points (for user stories with points:X labels)"
echo ""
echo "For epic linking and component assignment, please"
echo "refer to the setup guide at:"
echo "docs/logs/2025-05-17/github-project-setup-guide.md"