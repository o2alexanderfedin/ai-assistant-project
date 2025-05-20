#!/bin/bash

# Script to update the Parent Link field using variable substitution instead of a file

MUTATION='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { 
        text: $text
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
'

# Execute the mutation with variables
gh api graphql \
  -f query="$MUTATION" \
  -f projectId="PVT_kwHOBJ7Qkc4A5SDb" \
  -f itemId="PVTI_lAHOBJ7Qkc4A5SDbzgahC54" \
  -f fieldId="PVTF_lAHOBJ7Qkc4A5SDbzguIr2Y" \
  -f text="[#71](https://github.com/o2alexanderfedin/ai-assistant-project/issues/71) - Test Epic Issue"