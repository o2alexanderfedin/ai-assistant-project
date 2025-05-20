#!/usr/bin/env python3

"""
This script lists all project items in the GitHub Project,
including their IDs, content, and field values.
"""

import json
import subprocess
import sys

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

def get_project_items():
    """Get all project items"""
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
                        name
                      }
                    }
                  }
                  ... on ProjectV2ItemFieldNumberValue {
                    number
                    field {
                      ... on ProjectV2FieldCommon {
                        name
                      }
                    }
                  }
                  ... on ProjectV2ItemFieldTextValue {
                    text
                    field {
                      ... on ProjectV2FieldCommon {
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
                    owner {
                      login
                    }
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
    return all_nodes

def main():
    """Main function to list project items"""
    print("Listing all project items...")
    
    project_items = get_project_items()
    
    # Create a mapping of issue number to project item ID
    issue_to_item = {}
    
    for item in project_items:
        content = item.get("content", {})
        if not content:
            continue
            
        issue_repo = content.get("repository", {})
        if issue_repo.get("name") == REPO and issue_repo.get("owner", {}).get("login") == OWNER:
            issue_number = content.get("number")
            if issue_number:
                issue_to_item[str(issue_number)] = {
                    "item_id": item.get("id"),
                    "title": content.get("title"),
                    "fields": {}
                }
                
                # Extract field values
                field_values = item.get("fieldValues", {}).get("nodes", [])
                for field_value in field_values:
                    field_name = field_value.get("field", {}).get("name")
                    
                    if "name" in field_value:
                        # SingleSelectValue
                        issue_to_item[str(issue_number)]["fields"][field_name] = field_value.get("name")
                    elif "number" in field_value:
                        # NumberValue
                        issue_to_item[str(issue_number)]["fields"][field_name] = field_value.get("number")
                    elif "text" in field_value:
                        # TextValue
                        issue_to_item[str(issue_number)]["fields"][field_name] = field_value.get("text")
    
    # Print the mapping
    print("\nMapped Issue Numbers to Project Item IDs:")
    for issue_number, item_data in sorted(issue_to_item.items(), key=lambda x: int(x[0])):
        print(f"Issue #{issue_number} - {item_data['title']}:")
        print(f"  Project Item ID: {item_data['item_id']}")
        print("  Fields:")
        for field_name, field_value in item_data.get("fields", {}).items():
            print(f"    {field_name}: {field_value}")
        print()
    
    # Write the mapping to a file for other scripts to use
    with open("project_items.json", "w") as f:
        json.dump(issue_to_item, f, indent=2)
    
    print(f"\nIssue to project item mapping written to project_items.json")

if __name__ == "__main__":
    main()