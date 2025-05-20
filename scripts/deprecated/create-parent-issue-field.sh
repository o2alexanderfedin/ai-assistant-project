#!/bin/bash
# Create Parent Issue field for GitHub Project and set values for subtasks
# This script identifies subtasks and links them to their parent issues

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Creating Parent Issue field for GitHub Project #$PROJECT_NUM..."

# Get all issues that could have subtasks (exclude epics as they have a separate field)
echo "Getting potential parent issues..."
PARENT_ISSUES=$(gh issue list --json number,title,labels --repo "$REPO" | \
  jq '[.[] | select(.labels | map(.name) | (contains(["task"]) or contains(["user-story"])) and (contains(["epic"]) | not))]')

PARENT_COUNT=$(echo "$PARENT_ISSUES" | jq '. | length')
echo "Found $PARENT_COUNT potential parent issues."

# Identify actual parent issues by looking for issues with subtasks
ACTUAL_PARENTS=()
ACTUAL_PARENT_TITLES=""

echo "Analyzing issues to find actual parents..."
for i in $(seq 0 $(($PARENT_COUNT-1))); do
  ISSUE_NUM=$(echo "$PARENT_ISSUES" | jq -r ".[$i].number")
  ISSUE_TITLE=$(echo "$PARENT_ISSUES" | jq -r ".[$i].title")
  
  # Check if any issue refers to this one as a parent
  SUBTASK_COUNT=$(gh issue list --json body --repo "$REPO" | \
    jq "[.[] | select(.body | contains(\"Subtask of #$ISSUE_NUM\") or contains(\"Parent: #$ISSUE_NUM\"))] | length")
  
  if [ "$SUBTASK_COUNT" -gt 0 ]; then
    echo "  Found parent issue #$ISSUE_NUM: $ISSUE_TITLE with $SUBTASK_COUNT subtasks"
    ACTUAL_PARENTS+=($ISSUE_NUM)
    
    # Escape commas for the single-select options
    ISSUE_TITLE_ESCAPED=$(echo "$ISSUE_TITLE" | sed 's/,/\\,/g')
    
    if [ -z "$ACTUAL_PARENT_TITLES" ]; then
      ACTUAL_PARENT_TITLES="$ISSUE_TITLE_ESCAPED"
    else
      ACTUAL_PARENT_TITLES="$ACTUAL_PARENT_TITLES,$ISSUE_TITLE_ESCAPED"
    fi
  fi
done

# Only proceed if we found actual parents
if [ ${#ACTUAL_PARENTS[@]} -eq 0 ]; then
  echo "❌ No parent issues with subtasks found. Exiting."
  exit 1
fi

# Create the Parent Issue field
echo "Creating Parent Issue field with options: $ACTUAL_PARENT_TITLES"
FIELD_CREATION=$(gh projects field-create $PROJECT_NUM --user '@me' --name "Parent Issue" \
  --data-type "SINGLE_SELECT" --single-select-options "$ACTUAL_PARENT_TITLES" --format json)

echo "✅ Parent Issue field created"

# Get project data
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

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.id')
PARENT_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Parent Issue")')
PARENT_FIELD_ID=$(echo "$PARENT_FIELD_DATA" | jq -r '.id')

echo "Project ID: $PROJECT_ID"
echo "Parent Issue field ID: $PARENT_FIELD_ID"

# For each parent, find its subtasks and set the field
for PARENT_NUM in "${ACTUAL_PARENTS[@]}"; do
  echo "Processing subtasks for parent #$PARENT_NUM..."
  
  # Get the parent issue title again
  PARENT_TITLE=$(echo "$PARENT_ISSUES" | jq -r ".[] | select(.number==$PARENT_NUM) | .title")
  
  # Get the option ID for this parent
  PARENT_OPTION_ID=$(echo "$PARENT_FIELD_DATA" | jq -r ".options[] | select(.name==\"$PARENT_TITLE\") | .id")
  
  if [ -z "$PARENT_OPTION_ID" ]; then
    echo "  ⚠️ Could not find option ID for parent: $PARENT_TITLE"
    continue
  fi
  
  # Find all subtasks of this parent
  SUBTASKS=$(gh issue list --json number,title,body --repo "$REPO" | \
    jq "[.[] | select(.body | contains(\"Subtask of #$PARENT_NUM\") or contains(\"Parent: #$PARENT_NUM\"))]")
  
  SUBTASK_COUNT=$(echo "$SUBTASKS" | jq '. | length')
  echo "  Found $SUBTASK_COUNT subtasks for parent #$PARENT_NUM"
  
  # Process each subtask
  for j in $(seq 0 $(($SUBTASK_COUNT-1))); do
    SUBTASK_NUM=$(echo "$SUBTASKS" | jq -r ".[$j].number")
    SUBTASK_TITLE=$(echo "$SUBTASKS" | jq -r ".[$j].title")
    
    echo "  Processing subtask #$SUBTASK_NUM: $SUBTASK_TITLE"
    
    # Get item ID for this subtask
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
    
    ITEM_ID=$(echo "$ITEM_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number==$SUBTASK_NUM) | .id")
    
    if [ -z "$ITEM_ID" ]; then
      echo "    ⚠️ Subtask #$SUBTASK_NUM not found in project"
      continue
    fi
    
    # Set Parent Issue field
    echo "    Setting Parent Issue to: $PARENT_TITLE"
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
    ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$PARENT_FIELD_ID -F value=$PARENT_OPTION_ID > /dev/null
    
    echo "    ✅ Linked subtask #$SUBTASK_NUM to parent #$PARENT_NUM"
  done
done

echo ""
echo "🎉 Parent Issue field creation and linking complete!"
echo ""
echo "All subtasks have been linked to their parent issues where possible."
echo "For any subtasks that couldn't be linked automatically, you can set the"
echo "Parent Issue field manually using the GitHub web UI."