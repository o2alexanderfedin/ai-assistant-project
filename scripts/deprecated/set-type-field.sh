#!/bin/bash
# Set Type field for an issue in GitHub Project using GraphQL
# Usage: ./set-type-field.sh [project_number] [item_id] [type]
# Example: ./set-type-field.sh 2 PVTI_123 "Epic"

set -e

PROJECT_NUM=$1
ITEM_ID=$2
TYPE_VALUE=$3

if [ -z "$PROJECT_NUM" ] || [ -z "$ITEM_ID" ] || [ -z "$TYPE_VALUE" ]; then
  echo "Usage: $0 [project_number] [item_id] [type]"
  echo "Example: $0 2 PVTI_123 \"Epic\""
  exit 1
fi

# Get the Type field ID
echo "Getting Type field ID..."
TYPE_FIELD_DATA=$(gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
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
  }
' -F owner=o2alexanderfedin -F number=$PROJECT_NUM)

# Extract Type field ID and option ID
TYPE_FIELD_ID=$(echo "$TYPE_FIELD_DATA" | jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Type") | .id')
OPTION_ID=$(echo "$TYPE_FIELD_DATA" | jq -r ".data.user.projectV2.fields.nodes[] | select(.name==\"Type\") | .options[] | select(.name==\"$TYPE_VALUE\") | .id")

if [ -z "$TYPE_FIELD_ID" ]; then
  echo "❌ Could not find Type field"
  exit 1
fi

if [ -z "$OPTION_ID" ]; then
  echo "❌ Could not find option for type: $TYPE_VALUE"
  exit 1
fi

echo "Type field ID: $TYPE_FIELD_ID"
echo "Option ID for '$TYPE_VALUE': $OPTION_ID"

# Set the Type field
echo "Setting Type field to '$TYPE_VALUE'..."
RESULT=$(gh api graphql -f query='
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
      projectV2Item {
        id
      }
    }
  }
' -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$TYPE_FIELD_ID -F value=$OPTION_ID)

echo "✅ Field updated successfully"