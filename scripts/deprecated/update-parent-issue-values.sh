#!/bin/bash
# update-parent-issue-values.sh
# Sets the built-in "Parent issue" field values for GitHub Project items based on epic links in issue bodies

set -e  # Exit on error

# Configuration
PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"
ORG_OR_USER="o2alexanderfedin"

echo "🔍 Updating built-in Parent issue field values for GitHub Project #$PROJECT_NUM..."

# Get project ID 
echo "Getting project information..."
PROJECT_DATA=$(gh api graphql -f query='{
  user(login: "'$ORG_OR_USER'") {
    projectV2(number: '$PROJECT_NUM') {
      id
      title
    }
  }
}')

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.id')
PROJECT_TITLE=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.title')

if [ -z "$PROJECT_ID" ]; then
  echo "❌ Could not find project #$PROJECT_NUM. Please check the project number."
  exit 1
fi

echo "Found project: $PROJECT_TITLE (ID: $PROJECT_ID)"

# Get all epics (issues #1-7) with their details
echo "Getting all epic issues (#1-7)..."
EPICS=()
EPIC_IDS=()

for i in {1..7}; do
  EPIC_DATA=$(gh issue view $i --json id,number,title,body --repo "$REPO")
  EPICS[$i]="$EPIC_DATA"
  EPIC_IDS[$i]=$(echo "$EPIC_DATA" | jq -r '.id')
  EPIC_TITLE=$(echo "$EPIC_DATA" | jq -r '.title')
  echo "  Epic #$i: $EPIC_TITLE (Node ID: ${EPIC_IDS[$i]})"
done

# Get all items in the project
echo "Retrieving all project items..."
ALL_ITEMS=$(gh api graphql -f query='{
  user(login: "'$ORG_OR_USER'") {
    projectV2(number: '$PROJECT_NUM') {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              id
              number
              title
              body
            }
          }
        }
      }
    }
  }
}')

# Extract issue data
ITEMS=$(echo "$ALL_ITEMS" | jq -c '.data.user.projectV2.items.nodes[]')

echo "Processing issues to find Epic links..."
TEMP_FILE=$(mktemp)

# Process each item looking for Epic links in the format "- Epic: #X TITLE" or "Epic: #X"
echo "$ITEMS" | while read -r item; do
  ITEM_ID=$(echo "$item" | jq -r '.id')
  ISSUE_ID=$(echo "$item" | jq -r '.content.id')
  ISSUE_NUM=$(echo "$item" | jq -r '.content.number')
  ISSUE_TITLE=$(echo "$item" | jq -r '.content.title')
  BODY=$(echo "$item" | jq -r '.content.body')
  
  # Skip epics (issues #1-7)
  if [[ $ISSUE_NUM -ge 1 && $ISSUE_NUM -le 7 ]]; then
    continue
  fi
  
  # Look for "- Epic: #X" pattern anywhere in the body
  if [[ "$BODY" =~ [Ee]pic:\ *#([0-9]+) ]]; then
    PARENT_NUM="${BASH_REMATCH[1]}"
    
    # Only process epics 1-7
    if [[ $PARENT_NUM -ge 1 && $PARENT_NUM -le 7 ]]; then
      PARENT_ID="${EPIC_IDS[$PARENT_NUM]}"
      
      if [ -n "$PARENT_ID" ]; then
        echo "$ISSUE_NUM,$PARENT_NUM,$ITEM_ID,$PARENT_ID,$ISSUE_TITLE" >> "$TEMP_FILE"
        echo "  ✓ Found relationship: #$ISSUE_NUM '$ISSUE_TITLE' → Epic #$PARENT_NUM"
      else
        echo "  ⚠️ Found reference to Epic #$PARENT_NUM in issue #$ISSUE_NUM, but couldn't get epic ID"
      fi
    fi
  fi
done

# Count relationships
REL_COUNT=$(wc -l < "$TEMP_FILE" || echo 0)
echo "Found $REL_COUNT epic-based parent-child relationships."

if [ "$REL_COUNT" -eq 0 ]; then
  echo "No parent-child relationships found. Exiting."
  rm "$TEMP_FILE"
  exit 0
fi

# Get the field ID for the built-in Parent field
echo "Getting field information..."
FIELD_DATA=$(gh api graphql -f query='{
  user(login: "'$ORG_OR_USER'") {
    projectV2(number: '$PROJECT_NUM') {
      field(name: "Parent issue") {
        ... on ProjectV2Field {
          id
          name
        }
      }
    }
  }
}')

PARENT_FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.field.id')

if [ -z "$PARENT_FIELD_ID" ]; then
  echo "❌ Could not find Parent issue field ID. Using built-in field ID 'PARENT' instead."
  PARENT_FIELD_ID="PARENT"
fi

echo "Parent issue field ID: $PARENT_FIELD_ID"

# Update parent-child relationships
echo "Updating parent-child relationships..."
SUCCESS_COUNT=0

while IFS=, read -r CHILD_NUM PARENT_NUM CHILD_ITEM_ID PARENT_ISSUE_ID CHILD_TITLE; do
  echo "Processing: Child #$CHILD_NUM '$CHILD_TITLE' → Parent Epic #$PARENT_NUM"
  
  # Create a more detailed mutation to set the parent field
  MUTATION=$(cat <<EOF
mutation {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: "$PROJECT_ID"
      itemId: "$CHILD_ITEM_ID"
      fieldId: "$PARENT_FIELD_ID"
      value: {
        parentId: "$PARENT_ISSUE_ID"
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
EOF
)
  
  # Execute the mutation with proper escaping
  RESULT=$(echo "$MUTATION" | gh api graphql -f query=@- 2>&1)
  
  if [ $? -eq 0 ] && ! echo "$RESULT" | grep -q "error"; then
    echo "  ✅ Successfully linked child #$CHILD_NUM to parent #$PARENT_NUM"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo "  ❌ Failed to link child #$CHILD_NUM to parent #$PARENT_NUM"
    echo "  Error: $RESULT"
    
    # Try alternative approach with simpler mutation
    echo "  🔄 Trying alternative approach..."
    ALT_RESULT=$(gh api graphql -f query='
      mutation($project:ID!, $item:ID!, $field:ID!, $parentId:ID!) {
        updateProjectV2ItemFieldValue(
          input: {
            projectId: $project
            itemId: $item
            fieldId: $field
            value: { 
              parentId: $parentId
            }
          }
        ) {
          projectV2Item {
            id
          }
        }
      }
    ' -F project="$PROJECT_ID" -F item="$CHILD_ITEM_ID" -F field="$PARENT_FIELD_ID" -F parentId="$PARENT_ISSUE_ID" 2>&1)
    
    if [ $? -eq 0 ] && ! echo "$ALT_RESULT" | grep -q "error"; then
      echo "  ✅ Successfully linked child #$CHILD_NUM to parent #$PARENT_NUM (using alternate method)"
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      echo "  ❌ Failed with alternative approach"
      echo "  Error: $ALT_RESULT"
      
      # Last resort - try with hardcoded PARENT field ID
      echo "  🔄 Trying with hardcoded field ID..."
      LAST_RESULT=$(gh api graphql -f query='
        mutation($project:ID!, $item:ID!, $parentId:ID!) {
          updateProjectV2ItemFieldValue(
            input: {
              projectId: $project
              itemId: $item
              fieldId: "PARENT"
              value: { 
                parentId: $parentId
              }
            }
          ) {
            projectV2Item {
              id
            }
          }
        }
      ' -F project="$PROJECT_ID" -F item="$CHILD_ITEM_ID" -F parentId="$PARENT_ISSUE_ID" 2>&1)
      
      if [ $? -eq 0 ] && ! echo "$LAST_RESULT" | grep -q "error"; then
        echo "  ✅ Successfully linked child #$CHILD_NUM to parent #$PARENT_NUM (using hardcoded ID)"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      else
        echo "  ❌ All approaches failed"
      fi
    fi
  fi
done < "$TEMP_FILE"

# Sleep to allow changes to propagate
echo "Waiting for changes to propagate..."
sleep 3

# Print summary
echo ""
echo "🎉 Parent issue field update complete!"
echo "Found $REL_COUNT parent-child relationships based on Epic links in issues."
echo "Successfully updated $SUCCESS_COUNT out of $REL_COUNT relationships."
echo ""
echo "📋 Manual Verification Instructions:"
echo "1. Go to: https://github.com/users/$ORG_OR_USER/projects/$PROJECT_NUM"
echo "2. Check the 'Parent issue' field for user stories (issues #8 and above)"
echo "3. You should see their parent epics (issues #1-7) linked properly"
echo ""
echo "⚠️ If some relationships aren't showing correctly, please verify them manually in the GitHub UI."
echo "GitHub Projects API can be tricky with certain field types."

# Clean up
rm "$TEMP_FILE"