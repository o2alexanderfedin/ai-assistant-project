#!/bin/bash
# Set Epic Link field for user stories in GitHub Project
# This links user stories to their parent epics

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Setting Epic Link field for user stories in GitHub Project #$PROJECT_NUM..."

# Get project ID and fields
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
EPIC_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Epic")')
EPIC_FIELD_ID=$(echo "$EPIC_FIELD_DATA" | jq -r '.id')

echo "Project ID: $PROJECT_ID"
echo "Epic field ID: $EPIC_FIELD_ID"

if [ -z "$EPIC_FIELD_ID" ]; then
  echo "❌ Could not find Epic field. Make sure you've added an 'Epic' field (single select)."
  exit 1
fi

# Get all epics for lookup
echo "Getting epics..."
EPICS=$(gh issue list --label epic --json number,title --repo "$REPO")

# Get all user stories
echo "Getting user stories..."
USER_STORIES=$(gh issue list --label user-story --json number,title,body --repo "$REPO")
USER_STORY_COUNT=$(echo "$USER_STORIES" | jq '. | length')

# Process each user story
for i in $(seq 0 $(($USER_STORY_COUNT-1))); do
  STORY_NUM=$(echo "$USER_STORIES" | jq -r ".[$i].number")
  STORY_TITLE=$(echo "$USER_STORIES" | jq -r ".[$i].title")
  STORY_BODY=$(echo "$USER_STORIES" | jq -r ".[$i].body")
  
  echo "Processing user story #$STORY_NUM: $STORY_TITLE"
  
  # Extract parent epic number from body
  PARENT_EPIC_NUM=$(echo "$STORY_BODY" | grep -o -E "Epic: #[0-9]+" | grep -o -E "[0-9]+" | head -1 || echo "")
  
  if [ -z "$PARENT_EPIC_NUM" ]; then
    echo "  ⚠️ No parent epic found in description"
    continue
  fi
  
  # Get parent epic title
  PARENT_EPIC_TITLE=$(echo "$EPICS" | jq -r ".[] | select(.number==$PARENT_EPIC_NUM) | .title")
  
  if [ -z "$PARENT_EPIC_TITLE" ]; then
    echo "  ⚠️ Could not find epic #$PARENT_EPIC_NUM"
    continue
  fi
  
  echo "  Found parent epic: #$PARENT_EPIC_NUM - $PARENT_EPIC_TITLE"
  
  # Get epic option ID for this epic title
  EPIC_OPTION_ID=$(echo "$EPIC_FIELD_DATA" | jq -r ".options[] | select(.name==\"$PARENT_EPIC_TITLE\") | .id")
  
  if [ -z "$EPIC_OPTION_ID" ]; then
    echo "  ⚠️ No matching option found for epic: $PARENT_EPIC_TITLE"
    
    # Get all available options for debugging
    echo "  Available options:"
    echo "$EPIC_FIELD_DATA" | jq -r '.options[].name'
    
    continue
  fi
  
  # Get item ID for this user story
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
    echo "  ⚠️ User story #$STORY_NUM not found in project"
    continue
  fi
  
  # Set Epic Link field
  echo "  Setting Epic Link to: $PARENT_EPIC_TITLE"
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
  ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$EPIC_FIELD_ID -F value=$EPIC_OPTION_ID > /dev/null
  
  echo "  ✅ Linked user story #$STORY_NUM to epic #$PARENT_EPIC_NUM"
done

echo "🎉 Epic Link update complete!"
echo ""
echo "All user stories have been linked to their parent epics where possible."
echo "For any stories that couldn't be linked automatically, you can set the"
echo "Epic field manually using the GitHub web UI."