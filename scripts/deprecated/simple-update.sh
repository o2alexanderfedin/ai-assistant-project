#!/bin/bash

# Simple script to update the Parent Link field directly

cat > /tmp/mutation.graphql << EOF
mutation {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: "PVT_kwHOBJ7Qkc4A5SDb"
      itemId: "PVTI_lAHOBJ7Qkc4A5SDbzgahC54"
      fieldId: "PVTF_lAHOBJ7Qkc4A5SDbzguIr2Y"
      value: { 
        text: "[#71](https://github.com/o2alexanderfedin/ai-assistant-project/issues/71) - Test Epic Issue"
      }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
EOF

gh api graphql < /tmp/mutation.graphql