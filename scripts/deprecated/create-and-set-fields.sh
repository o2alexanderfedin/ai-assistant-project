#!/bin/bash
# Create missing fields and set values for GitHub Project
# This script will create any missing fields and then set values for all items

set -e  # Exit on error

PROJECT_NUM=2
REPO="o2alexanderfedin/ai-assistant-project"

echo "🚀 Updating GitHub Project #$PROJECT_NUM fields..."

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

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.id')
echo "Project ID: $PROJECT_ID"

# Check for Type field
TYPE_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Type") | .id')
if [ -z "$TYPE_FIELD_ID" ]; then
  echo "Creating Type field..."
  TYPE_FIELD_DATA=$(gh api graphql -f query='
    mutation($projectId:ID!) {
      createProjectV2Field(
        input: {
          projectId: $projectId,
          dataType: SINGLE_SELECT,
          name: "Type",
          singleSelectOptions: ["Epic", "User Story", "Task"]
        }
      ) {
        field {
          id
          name
          ... on ProjectV2SingleSelectField {
            options {
              id
              name
            }
          }
        }
      }
    }
  ' -F projectId=$PROJECT_ID)
  TYPE_FIELD_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.id')
  TYPE_EPIC_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options[] | select(.name=="Epic") | .id')
  TYPE_STORY_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options[] | select(.name=="User Story") | .id')
else
  TYPE_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Type")')
  TYPE_EPIC_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.options[] | select(.name=="Epic") | .id')
  TYPE_STORY_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.options[] | select(.name=="User Story") | .id')
fi
echo "Type field ID: $TYPE_FIELD_ID"

# Check for Priority field
PRIORITY_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Priority") | .id')
if [ -z "$PRIORITY_FIELD_ID" ]; then
  echo "Creating Priority field..."
  PRIORITY_FIELD_DATA=$(gh api graphql -f query='
    mutation($projectId:ID!) {
      createProjectV2Field(
        input: {
          projectId: $projectId,
          dataType: SINGLE_SELECT,
          name: "Priority",
          singleSelectOptions: ["High", "Medium", "Low"]
        }
      ) {
        field {
          id
          name
          ... on ProjectV2SingleSelectField {
            options {
              id
              name
            }
          }
        }
      }
    }
  ' -F projectId=$PROJECT_ID)
  PRIORITY_FIELD_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.id')
  PRIORITY_HIGH_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options[] | select(.name=="High") | .id')
  PRIORITY_MEDIUM_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options[] | select(.name=="Medium") | .id')
  PRIORITY_LOW_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options[] | select(.name=="Low") | .id')
else
  PRIORITY_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Priority")')
  PRIORITY_HIGH_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.options[] | select(.name=="High") | .id')
  PRIORITY_MEDIUM_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.options[] | select(.name=="Medium") | .id')
  PRIORITY_LOW_ID=$(echo "$PRIORITY_FIELD_DATA" | jq -r '.options[] | select(.name=="Low") | .id')
fi
echo "Priority field ID: $PRIORITY_FIELD_ID"

# Check for Story Points field
POINTS_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Story Points") | .id')
if [ -z "$POINTS_FIELD_ID" ]; then
  echo "Creating Story Points field..."
  POINTS_FIELD_DATA=$(gh api graphql -f query='
    mutation($projectId:ID!) {
      createProjectV2Field(
        input: {
          projectId: $projectId,
          dataType: NUMBER,
          name: "Story Points"
        }
      ) {
        field {
          id
          name
        }
      }
    }
  ' -F projectId=$PROJECT_ID)
  POINTS_FIELD_ID=$(echo "$POINTS_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.id')
fi
echo "Story Points field ID: $POINTS_FIELD_ID"

# Check for Epic field
EPIC_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Epic") | .id')
if [ -z "$EPIC_FIELD_ID" ]; then
  echo "Creating Epic field..."
  # Get all epic titles for options
  EPIC_TITLES=$(gh issue list --label epic --json title --repo "$REPO" | jq -r '.[].title')
  
  # Convert titles to JSON array for GraphQL
  EPIC_OPTIONS="["
  for TITLE in $EPIC_TITLES; do
    EPIC_OPTIONS="$EPIC_OPTIONS\"$TITLE\","
  done
  EPIC_OPTIONS="${EPIC_OPTIONS%,}]"  # Remove last comma and close array
  
  # Create field with options
  EPIC_FIELD_DATA=$(gh api graphql -f query='
    mutation($projectId:ID!, $options:[String!]!) {
      createProjectV2Field(
        input: {
          projectId: $projectId,
          dataType: SINGLE_SELECT,
          name: "Epic",
          singleSelectOptions: $options
        }
      ) {
        field {
          id
          name
          ... on ProjectV2SingleSelectField {
            options {
              id
              name
            }
          }
        }
      }
    }
  ' -F projectId=$PROJECT_ID -F options="$EPIC_OPTIONS")
  EPIC_FIELD_ID=$(echo "$EPIC_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.id')
  EPIC_FIELD_OPTIONS=$(echo "$EPIC_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options')
else
  # Get existing options
  EPIC_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Epic")')
  EPIC_FIELD_OPTIONS=$(echo "$EPIC_FIELD_DATA" | jq -r '.options')
fi
echo "Epic field ID: $EPIC_FIELD_ID"

# Check for Component field
COMPONENT_FIELD_ID=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component") | .id')
if [ -z "$COMPONENT_FIELD_ID" ]; then
  echo "Creating Component field..."
  COMPONENT_FIELD_DATA=$(gh api graphql -f query='
    mutation($projectId:ID!) {
      createProjectV2Field(
        input: {
          projectId: $projectId,
          dataType: SINGLE_SELECT,
          name: "Component",
          singleSelectOptions: ["Core Agents", "MCP", "Workflow", "Shared Components", "External Integration", "Testing"]
        }
      ) {
        field {
          id
          name
          ... on ProjectV2SingleSelectField {
            options {
              id
              name
            }
          }
        }
      }
    }
  ' -F projectId=$PROJECT_ID)
  COMPONENT_FIELD_ID=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.id')
  COMPONENT_FIELD_OPTIONS=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.data.createProjectV2Field.field.options')
else
  COMPONENT_FIELD_DATA=$(echo "$PROJECT_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Component")')
  COMPONENT_FIELD_OPTIONS=$(echo "$COMPONENT_FIELD_DATA" | jq -r '.options')
fi
echo "Component field ID: $COMPONENT_FIELD_ID"

# Get all project items
echo "Getting project items..."
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
              body
            }
          }
        }
      }
    }
  }
}')

# Get all epics
EPICS=$(gh issue list --label epic --json number,title --repo "$REPO")
EPIC_COUNT=$(echo "$EPICS" | jq '. | length')

# Create a map of epic titles to option IDs
declare -A EPIC_TITLE_TO_ID
for OPTION in $(echo "$EPIC_FIELD_OPTIONS" | jq -c '.[]'); do
  OPTION_NAME=$(echo "$OPTION" | jq -r '.name')
  OPTION_ID=$(echo "$OPTION" | jq -r '.id')
  EPIC_TITLE_TO_ID["$OPTION_NAME"]="$OPTION_ID"
done

# Create a map of component names to option IDs
declare -A COMPONENT_TO_ID
for OPTION in $(echo "$COMPONENT_FIELD_OPTIONS" | jq -c '.[]'); do
  OPTION_NAME=$(echo "$OPTION" | jq -r '.name')
  OPTION_ID=$(echo "$OPTION" | jq -r '.id')
  COMPONENT_TO_ID["$OPTION_NAME"]="$OPTION_ID"
done

# Process epics first
echo "Processing epics..."
for i in $(seq 0 $(($EPIC_COUNT-1))); do
  EPIC_NUM=$(echo "$EPICS" | jq -r ".[$i].number")
  EPIC_TITLE=$(echo "$EPICS" | jq -r ".[$i].title")
  
  echo "Processing epic #$EPIC_NUM: $EPIC_TITLE"
  
  # Get labels and determine component and priority
  LABELS=$(gh issue view $EPIC_NUM --json labels --repo "$REPO" | jq -r '.labels[].name')
  
  # Determine component
  COMPONENT=""
  if echo "$LABELS" | grep -q "core-agents"; then
    COMPONENT="Core Agents"
  elif echo "$LABELS" | grep -q "mcp\|communication"; then
    COMPONENT="MCP"
  elif echo "$LABELS" | grep -q "workflow"; then
    COMPONENT="Workflow"
  elif echo "$LABELS" | grep -q "infrastructure"; then
    if echo "$EPIC_TITLE" | grep -q "External Integration"; then
      COMPONENT="External Integration"
    else
      COMPONENT="Shared Components"
    fi
  elif echo "$EPIC_TITLE" | grep -q "Testing"; then
    COMPONENT="Testing"
  fi
  
  # Determine priority
  PRIORITY=""
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY="Medium"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY="Low"
  fi
  
  # Get item ID in project
  ITEM_ID=$(echo "$ITEMS_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number==$EPIC_NUM) | .id")
  
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
  if [ ! -z "$PRIORITY" ]; then
    echo "  Setting Priority to $PRIORITY"
    PRIORITY_OPTION_ID=""
    if [ "$PRIORITY" = "High" ]; then
      PRIORITY_OPTION_ID="$PRIORITY_HIGH_ID"
    elif [ "$PRIORITY" = "Medium" ]; then
      PRIORITY_OPTION_ID="$PRIORITY_MEDIUM_ID"
    elif [ "$PRIORITY" = "Low" ]; then
      PRIORITY_OPTION_ID="$PRIORITY_LOW_ID"
    fi
    
    if [ ! -z "$PRIORITY_OPTION_ID" ]; then
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
  fi
  
  # Set Component field
  if [ ! -z "$COMPONENT" ]; then
    echo "  Setting Component to $COMPONENT"
    COMPONENT_OPTION_ID="${COMPONENT_TO_ID[$COMPONENT]}"
    
    if [ ! -z "$COMPONENT_OPTION_ID" ]; then
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
      ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$COMPONENT_FIELD_ID -F value=$COMPONENT_OPTION_ID > /dev/null
    fi
  fi
  
  echo "  ✅ Updated epic #$EPIC_NUM"
done

# Get all user stories
echo "Processing user stories..."
USER_STORIES=$(gh issue list --label user-story --json number,title,body,labels --repo "$REPO")
USER_STORY_COUNT=$(echo "$USER_STORIES" | jq '. | length')

# Process user stories
for i in $(seq 0 $(($USER_STORY_COUNT-1))); do
  STORY_NUM=$(echo "$USER_STORIES" | jq -r ".[$i].number")
  STORY_TITLE=$(echo "$USER_STORIES" | jq -r ".[$i].title")
  STORY_BODY=$(echo "$USER_STORIES" | jq -r ".[$i].body")
  LABELS=$(echo "$USER_STORIES" | jq -r ".[$i].labels[].name" 2>/dev/null || echo "")
  
  echo "Processing user story #$STORY_NUM: $STORY_TITLE"
  
  # Get item ID in project
  ITEM_ID=$(echo "$ITEMS_DATA" | jq -r ".data.user.projectV2.items.nodes[] | select(.content.number==$STORY_NUM) | .id")
  
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
  PRIORITY=""
  if echo "$LABELS" | grep -q "priority:highest"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:high"; then
    PRIORITY="High"
  elif echo "$LABELS" | grep -q "priority:medium"; then
    PRIORITY="Medium"
  elif echo "$LABELS" | grep -q "priority:low"; then
    PRIORITY="Low"
  fi
  
  if [ ! -z "$PRIORITY" ]; then
    echo "  Setting Priority to $PRIORITY"
    PRIORITY_OPTION_ID=""
    if [ "$PRIORITY" = "High" ]; then
      PRIORITY_OPTION_ID="$PRIORITY_HIGH_ID"
    elif [ "$PRIORITY" = "Medium" ]; then
      PRIORITY_OPTION_ID="$PRIORITY_MEDIUM_ID"
    elif [ "$PRIORITY" = "Low" ]; then
      PRIORITY_OPTION_ID="$PRIORITY_LOW_ID"
    fi
    
    if [ ! -z "$PRIORITY_OPTION_ID" ]; then
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
  
  # Set Epic Link field by finding parent epic in body
  PARENT_EPIC_NUM=$(echo "$STORY_BODY" | grep -o -E "Epic: #[0-9]+" | grep -o -E "[0-9]+" | head -1 || echo "")
  
  if [ ! -z "$PARENT_EPIC_NUM" ]; then
    PARENT_EPIC_TITLE=$(echo "$EPICS" | jq -r ".[] | select(.number==$PARENT_EPIC_NUM) | .title")
    
    if [ ! -z "$PARENT_EPIC_TITLE" ]; then
      echo "  Setting Epic Link to $PARENT_EPIC_TITLE"
      EPIC_OPTION_ID="${EPIC_TITLE_TO_ID[$PARENT_EPIC_TITLE]}"
      
      if [ ! -z "$EPIC_OPTION_ID" ]; then
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
      else
        echo "  ⚠️ Could not find option ID for epic: $PARENT_EPIC_TITLE"
      fi
    else
      echo "  ⚠️ Could not find epic #$PARENT_EPIC_NUM"
    fi
  else
    echo "  ⚠️ No parent epic found in description"
  fi
  
  # Determine component
  COMPONENT=""
  if echo "$LABELS" | grep -q "core-agents"; then
    COMPONENT="Core Agents"
  elif echo "$LABELS" | grep -q "mcp\|communication"; then
    COMPONENT="MCP"
  elif echo "$LABELS" | grep -q "workflow"; then
    COMPONENT="Workflow"
  elif echo "$LABELS" | grep -q "documentation\|infrastructure"; then
    if echo "$LABELS" | grep -q "external"; then
      COMPONENT="External Integration"
    else
      COMPONENT="Shared Components"
    fi
  elif echo "$LABELS" | grep -q "testing\|test"; then
    COMPONENT="Testing"
  elif [ ! -z "$PARENT_EPIC_NUM" ]; then
    # Derive component from epic if available
    EPIC_LABELS=$(gh issue view $PARENT_EPIC_NUM --json labels --repo "$REPO" | jq -r '.labels[].name' 2>/dev/null || echo "")
    
    if echo "$EPIC_LABELS" | grep -q "core-agents"; then
      COMPONENT="Core Agents"
    elif echo "$EPIC_LABELS" | grep -q "mcp\|communication"; then
      COMPONENT="MCP"
    elif echo "$EPIC_LABELS" | grep -q "workflow"; then
      COMPONENT="Workflow"
    elif echo "$EPIC_LABELS" | grep -q "infrastructure"; then
      if echo "$PARENT_EPIC_TITLE" | grep -q "External Integration"; then
        COMPONENT="External Integration"
      else
        COMPONENT="Shared Components"
      fi
    elif echo "$PARENT_EPIC_TITLE" | grep -q "Testing"; then
      COMPONENT="Testing"
    fi
  fi
  
  # Set Component field
  if [ ! -z "$COMPONENT" ]; then
    echo "  Setting Component to $COMPONENT"
    COMPONENT_OPTION_ID="${COMPONENT_TO_ID[$COMPONENT]}"
    
    if [ ! -z "$COMPONENT_OPTION_ID" ]; then
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
      ' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$COMPONENT_FIELD_ID -F value=$COMPONENT_OPTION_ID > /dev/null
    else
      echo "  ⚠️ Could not find option ID for component: $COMPONENT"
    fi
  else
    echo "  ⚠️ Could not determine component"
  fi
  
  echo "  ✅ Updated user story #$STORY_NUM"
done

echo "🎉 All fields updated!"
echo ""
echo "Fields that were created/updated:"
echo "- Type (Epic or User Story)"
echo "- Priority (High, Medium, Low)"
echo "- Story Points (for user stories)"
echo "- Epic (linking user stories to parent epics)"
echo "- Component (assigned based on labels and epic relationships)"
echo ""
echo "Check the GitHub Project at: https://github.com/users/o2alexanderfedin/projects/$PROJECT_NUM"