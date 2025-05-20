#!/bin/bash

# Direct update script for custom Parent Link field

# Config parameters 
PROJECT_ID="PVT_kwHOBJ7Qkc4A5SDb"  # Project #2
FIELD_ID="PVTF_lAHOBJ7Qkc4A5SDbzguIr2Y"  # "Parent Link" field

# Use the direct item ID from the project item-list command
ITEM_ID="PVTI_lAHOBJ7Qkc4A5SDbzgahC54"  # Item ID for issue #73

echo "Found item ID: $ITEM_ID"

# Now set the parent link value
echo "Setting parent link field..."
PARENT_LINK="[#71](https://github.com/o2alexanderfedin/ai-assistant-project/issues/71) - Test Epic Issue"

echo "mutation {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: \"$PROJECT_ID\"
      itemId: \"$ITEM_ID\"
      fieldId: \"$FIELD_ID\"
      value: { 
        text: \"$PARENT_LINK\"
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}" > /tmp/mutation.graphql

gh api graphql -f query=@/tmp/mutation.graphql

echo "Done!"