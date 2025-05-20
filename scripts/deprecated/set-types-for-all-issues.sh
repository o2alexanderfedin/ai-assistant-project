#!/bin/bash

# This script sets types for all issues in the project
# It identifies epics and user stories based on labels

# ----------- CONFIG ----------- #
OWNER="o2alexanderfedin"
REPO="ai-assistant-project"
PROJECT_NUM="2"  # Project number
TYPE_FIELD_ID="PVTF_lADOAGD9swUAM8qzgHfWyQ"  # Type field ID

# Get all issues with their labels
echo "🔍 Getting all issues with their labels..."
ALL_ISSUES=$(gh issue list --repo $OWNER/$REPO --limit 100 --json number,title,labels)

# Get all project items
echo "📋 Getting all project items..."
PROJECT_ITEMS=$(gh project item-list $PROJECT_NUM --owner $OWNER --format json)
ITEMS_COUNT=$(echo "$PROJECT_ITEMS" | jq '.items | length')
echo "Found $ITEMS_COUNT items in the project"

# Process each project item
echo "🔄 Setting types for project items..."
SUCCESS_COUNT=0
FAILURE_COUNT=0
ALREADY_SET=0

# Extract item nodes with IDs and content URLs
ITEM_NODES=$(echo "$PROJECT_ITEMS" | jq -c '.items[] | {id: .id, content: .content}')

for ITEM in $ITEM_NODES; do
  ITEM_ID=$(echo "$ITEM" | jq -r '.id')
  CONTENT_URL=$(echo "$ITEM" | jq -r '.content.url // empty')
  
  # Skip if not an issue or no URL
  if [ -z "$CONTENT_URL" ]; then
    continue
  fi
  
  # Extract issue number from URL
  ISSUE_NUM=$(echo "$CONTENT_URL" | grep -oE '/issues/([0-9]+)' | cut -d/ -f3)
  
  if [ -z "$ISSUE_NUM" ]; then
    continue
  fi
  
  # Get issue title for logging
  ISSUE_TITLE=$(echo "$ALL_ISSUES" | jq -r ".[] | select(.number == $ISSUE_NUM) | .title")
  echo "Processing issue #$ISSUE_NUM: '$ISSUE_TITLE'..."
  
  # Check issue labels to determine type
  LABELS=$(echo "$ALL_ISSUES" | jq -r ".[] | select(.number == $ISSUE_NUM) | .labels[].name")
  
  TYPE_VALUE=""
  if echo "$LABELS" | grep -q "epic"; then
    TYPE_VALUE="Epic"
  elif echo "$LABELS" | grep -q "user-story"; then
    TYPE_VALUE="User Story"
  else
    # Default to User Story if no specific type label is found
    TYPE_VALUE="User Story"
  fi
  
  if [ -z "$TYPE_VALUE" ]; then
    echo "  ⚠️ Could not determine type for issue #$ISSUE_NUM, skipping"
    continue
  fi
  
  echo "  Setting type to: $TYPE_VALUE"
  
  # Update the type field for the item
  MUTATION='
  mutation($project:ID!, $item:ID!, $fieldId:ID!, $value:String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $project
      itemId: $item
      fieldId: $fieldId
      value: { 
        singleSelectOptionId: $value
      }
    }) {
      projectV2Item {
        id
      }
    }
  }'
  
  # Get project ID
  PROJECT_ID=$(echo "$PROJECT_ITEMS" | jq -r '.projectId')
  
  # Get option ID for the type value
  FIELD_INFO=$(gh api graphql -f query='
  query($owner:String!, $projectNumber:Int!, $fieldId:ID!) {
    organization(login: $owner) {
      projectV2(number: $projectNumber) {
        field(id: $fieldId) {
          ... on ProjectV2SingleSelectField {
            options {
              id
              name
            }
          }
        }
      }
    }
  }' -f owner="$OWNER" -f projectNumber="$PROJECT_NUM" -f fieldId="$TYPE_FIELD_ID")
  
  OPTION_ID=$(echo "$FIELD_INFO" | jq -r ".data.organization.projectV2.field.options[] | select(.name == \"$TYPE_VALUE\") | .id")
  
  if [ -z "$OPTION_ID" ]; then
    echo "  ❌ Could not find option ID for type '$TYPE_VALUE'"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    continue
  fi
  
  # Execute the mutation to update the type field
  RESULT=$(gh api graphql -f query="$MUTATION" \
    -f project="$PROJECT_ID" \
    -f item="$ITEM_ID" \
    -f fieldId="$TYPE_FIELD_ID" \
    -f value="$OPTION_ID" 2>/dev/null)
  
  if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
    echo "  ✅ Successfully set type to '$TYPE_VALUE' for issue #$ISSUE_NUM"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to set type for issue #$ISSUE_NUM"
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
  fi
done

echo ""
echo "🏁 Finished setting types for project items!"
echo "✅ Updated: $SUCCESS_COUNT items"
echo "⚠️ Already set or skipped: $ALREADY_SET items"
echo "❌ Failed: $FAILURE_COUNT items"
echo ""
echo "All issues should now have appropriate types in the project."