#!/usr/bin/env python3

import json
import subprocess

PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

def run_command(cmd):
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

query = """
query($projectId:ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2SingleSelectField {
                    name
                  }
                }
              }
            }
          }
          content {
            ... on Issue {
              number
              title
            }
          }
        }
      }
    }
  }
}
"""

success, output = run_command([
    "gh", "api", "graphql",
    "-f", f"query={query}",
    "-f", f"projectId={PROJECT_ID}"
])

if success:
    data = json.loads(output)
    nodes = data.get("data", {}).get("node", {}).get("items", {}).get("nodes", [])

    for node in nodes:
        content = node.get("content", {})
        if content and content.get("number") == 8:
            field_values = node.get("fieldValues", {}).get("nodes", [])
            for field_value in field_values:
                if field_value.get("field", {}).get("name") == "Type":
                    print(f"Issue #8 type in project: {field_value.get('name')}")
                    break
else:
    print(f"Error: {output}")