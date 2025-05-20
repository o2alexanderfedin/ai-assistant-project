#!/bin/bash
# Create Epic field for GitHub Project
# This script only focuses on creating the Epic field and setting parent values

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Creating Epic field for GitHub Project #$PROJECT_NUM..."

# Get list of epic titles
echo "Getting epic titles..."
EPICS=$(gh issue list --label epic --json number,title --repo "$REPO")
EPIC_COUNT=$(echo "$EPICS" | jq '. | length')

# Create a comma-separated list of epic titles for options
EPIC_OPTIONS=""
for i in $(seq 0 $(($EPIC_COUNT-1))); do
  EPIC_TITLE=$(echo "$EPICS" | jq -r ".[$i].title")
  EPIC_TITLE_ESCAPED=$(echo "$EPIC_TITLE" | sed 's/,/\\,/g')  # Escape commas in titles
  
  if [ -z "$EPIC_OPTIONS" ]; then
    EPIC_OPTIONS="$EPIC_TITLE_ESCAPED"
  else
    EPIC_OPTIONS="$EPIC_OPTIONS,$EPIC_TITLE_ESCAPED"
  fi
done

# Create Epic field with all titles as options
echo "Creating Epic field with options: $EPIC_OPTIONS"
gh projects field-create $PROJECT_NUM --user '@me' --name "Epic" --data-type "SINGLE_SELECT" --single-select-options "$EPIC_OPTIONS" --format json

echo "✅ Epic field created"

# Now set epic links for user stories
echo "Setting Epic links for user stories..."

# Get all user stories
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
  
  # Try to get project items using GraphQL since the CLI doesn't have a direct items list command
  ITEMS_DATA=$(gh api graphql -f query='{
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
  
  ITEM_ID=$(echo "$ITEMS_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number==$STORY_NUM) | .id")
  
  if [ -z "$ITEM_ID" ]; then
    echo "  ⚠️ User story not found in project"
    continue
  fi
  
  # Get the field ID
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
  
  FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Epic") | .id')
  OPTION_ID=$(echo "$FIELD_DATA" | jq -r ".data.user.projectV2.fields.nodes[] | select(.name==\"Epic\") | .options[] | select(.name==\"$PARENT_EPIC_TITLE\") | .id")
  
  if [ -z "$FIELD_ID" ] || [ -z "$OPTION_ID" ]; then
    echo "  ⚠️ Could not find Epic field or option"
    continue
  fi
  
  # Set the Epic field
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
  ' -F project="PVT_kwHOBJ7Qkc4A5SDb" -F item="$ITEM_ID" -F field="$FIELD_ID" -F value="$OPTION_ID" > /dev/null
  
  echo "  ✅ Set Epic link"
done

echo "🎉 Epic field creation and linking complete!"