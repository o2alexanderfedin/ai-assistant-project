#!/usr/bin/env python3

"""
This script checks for user stories in the GitHub Project that don't have the Parent Issue field set.
"""

import json
import subprocess

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

def run_command(cmd):
    """Run a shell command and return the output"""
    try:
        result = subprocess.run(
            cmd, check=True, capture_output=True, text=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

def get_parent_issue_field_id():
    """Get the ID of the Parent Issue field in the project"""
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2FieldCommon {
                id
                name
                dataType
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
        fields = data.get("data", {}).get("node", {}).get("fields", {}).get("nodes", [])
        
        for field in fields:
            if field.get("name") == "Parent issue":
                return field.get("id")
        
        return None
    else:
        print(f"Failed to get field information: {output}")
        return None

def get_project_items_without_parent(parent_field_id):
    """Get project items without Parent Issue field set"""
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
              fieldValues(first: 20) {
                nodes {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                    field {
                      ... on ProjectV2SingleSelectField {
                        id
                        name
                      }
                    }
                  }
                  ... on ProjectV2ItemFieldTextValue {
                    text
                    field {
                      ... on ProjectV2FieldCommon {
                        id
                        name
                      }
                    }
                  }
                }
              }
              content {
                ... on Issue {
                  id
                  number
                  title
                  repository {
                    name
                  }
                }
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
      }
    }
    """
    
    all_nodes = []
    cursor = None
    has_next_page = True
    
    while has_next_page:
        # Build the query based on whether we have a cursor or not
        if cursor:
            paginated_query = query.replace(
                'items(first: 100)',
                f'items(first: 100, after: "{cursor}")'
            )
        else:
            paginated_query = query
            
        success, output = run_command([
            "gh", "api", "graphql",
            "-f", f"query={paginated_query}",
            "-f", f"projectId={PROJECT_ID}"
        ])
        
        if success:
            data = json.loads(output)
            items = data.get("data", {}).get("node", {}).get("items", {})
            nodes = items.get("nodes", [])
            all_nodes.extend(nodes)
            
            # Check if there's another page to fetch
            page_info = items.get("pageInfo", {})
            has_next_page = page_info.get("hasNextPage", False)
            cursor = page_info.get("endCursor")
            
            if has_next_page:
                print(f"Fetched {len(nodes)} items, getting next page...")
        else:
            print(f"Failed to get GitHub Project items: {output}")
            return []
    
    print(f"Total project items fetched: {len(all_nodes)}")
    
    missing_parent = []
    
    for node in all_nodes:
        content = node.get("content", {})
        if not content or content.get("repository", {}).get("name") != REPO:
            continue
        
        # Check if this is a user story and missing the Parent Issue field
        is_user_story = False
        has_parent = False
        
        field_values = node.get("fieldValues", {}).get("nodes", [])
        for field_value in field_values:
            field = field_value.get("field", {})
            
            if field.get("name") == "Type" and field_value.get("name") == "User Story":
                is_user_story = True
            
            if field.get("id") == parent_field_id and field_value.get("text"):
                has_parent = True
        
        if is_user_story and not has_parent:
            missing_parent.append({
                "issue_number": content.get("number"),
                "title": content.get("title"),
                "project_item_id": node.get("id")
            })
    
    return missing_parent

def main():
    """Check for user stories without Parent Issue field set"""
    # Get the Parent Issue field ID
    parent_field_id = get_parent_issue_field_id()
    if not parent_field_id:
        print("Parent Issue field not found in the project")
        return
    
    print(f"Parent Issue field ID: {parent_field_id}")
    
    # Get project items without Parent Issue field set
    missing_parent = get_project_items_without_parent(parent_field_id)
    
    if missing_parent:
        print(f"\nFound {len(missing_parent)} user stories without Parent Issue field set:")
        for item in missing_parent:
            print(f"Issue #{item['issue_number']} - {item['title']}")
    else:
        print("\nAll user stories have Parent Issue field set")

if __name__ == "__main__":
    main()