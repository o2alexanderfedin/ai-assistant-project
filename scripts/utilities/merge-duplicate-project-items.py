#!/usr/bin/env python3

"""
This script identifies and merges duplicate items in GitHub Project.
It preserves the lower-numbered issue and removes the higher-numbered duplicate.
"""

import json
import subprocess
import time
import sys

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

# Duplicates mapping - the key is the issue to keep, the value is the issue to remove
# Based on analysis, we want to keep the lower-numbered issues
DUPLICATES_TO_MERGE = {
    "9": "59",   # GitHub Task Monitoring
    "10": "60",  # Agent Lifecycle Management
    "11": "61",  # Orchestrator MCP Communication
    "12": "62",  # Task Analysis and Agent Matching
    "13": "63",  # Task Classification and Prioritization
    "14": "64",  # Agent Instance Creation
    "15": "65",  # Agent Template Management
    "16": "66",  # Secure Agent Creation
}

def run_command(cmd):
    """Run a shell command and return the output"""
    try:
        result = subprocess.run(
            cmd, check=True, capture_output=True, text=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

def load_project_items():
    """Load the project items from the JSON file"""
    try:
        with open("project_items.json", "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print("project_items.json not found. Please run list-project-items.py first.")
        sys.exit(1)

def get_project_item_details(item_id):
    """Get details for a single project item by ID"""
    query = """
    query($projectId:ID!, $itemId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          item(id: $itemId) {
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
        }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"itemId={item_id}"
    ])
    
    if success:
        data = json.loads(output)
        return data.get("data", {}).get("node", {}).get("item", {})
    else:
        print(f"Failed to get project item details: {output}")
        return None

def delete_project_item(item_id):
    """Delete a project item by ID"""
    query = """
    mutation($projectId:ID!, $itemId:ID!) {
      deleteProjectV2Item(input: {
        projectId: $projectId
        itemId: $itemId
      }) {
        deletedItemId
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"itemId={item_id}"
    ])
    
    if success:
        data = json.loads(output)
        deleted_id = data.get("data", {}).get("deleteProjectV2Item", {}).get("deletedItemId")
        if deleted_id:
            return True
        else:
            print(f"Failed to delete project item: No deleted ID returned")
            return False
    else:
        print(f"Failed to delete project item: {output}")
        return False

def analyze_duplicates(project_items):
    """Analyze the duplicate items and validate the duplication mapping"""
    print("Analyzing duplicate items...")
    
    # Group items by title
    items_by_title = {}
    for issue_number, item_data in project_items.items():
        title = item_data.get("title")
        if title not in items_by_title:
            items_by_title[title] = []
        items_by_title[title].append(issue_number)
    
    # Validate duplicates list
    duplicates_by_title = {title: issues for title, issues in items_by_title.items() if len(issues) > 1}
    
    print(f"Found {len(duplicates_by_title)} duplicate titles in the project")
    
    # Check if our mapping covers all duplicates
    all_duplicates_covered = True
    for title, issues in duplicates_by_title.items():
        issues_str = ", ".join(issues)
        found = False
        
        for keep, remove in DUPLICATES_TO_MERGE.items():
            if keep in issues and remove in issues:
                found = True
                break
        
        if not found:
            print(f"WARNING: No mapping found for duplicate title '{title}' with issues: {issues_str}")
            all_duplicates_covered = False
    
    if not all_duplicates_covered:
        print("Not all duplicates are covered in the DUPLICATES_TO_MERGE mapping.")
        user_input = input("Continue anyway? (y/n): ")
        if user_input.lower() != 'y':
            print("Exiting without making changes.")
            sys.exit(0)

def merge_duplicates(project_items):
    """Merge the duplicate items by removing the higher-numbered duplicates"""
    print("\nMerging duplicate items...")
    
    for keep, remove in DUPLICATES_TO_MERGE.items():
        print(f"\nProcessing duplicate pair: Keep #{keep}, Remove #{remove}")
        
        # Check if both issues exist in the project
        if keep not in project_items:
            print(f"  Issue #{keep} not found in project_items.json, skipping")
            continue
        
        if remove not in project_items:
            print(f"  Issue #{remove} not found in project_items.json, skipping")
            continue
        
        # Get the items to keep and remove
        keep_item = project_items[keep]
        remove_item = project_items[remove]
        
        # Print details about the items
        print(f"  Item to keep: #{keep} - {keep_item.get('title')}")
        print(f"    ID: {keep_item.get('item_id')}")
        print(f"    Fields: {json.dumps(keep_item.get('fields', {}), indent=2)}")
        
        print(f"  Item to remove: #{remove} - {remove_item.get('title')}")
        print(f"    ID: {remove_item.get('item_id')}")
        print(f"    Fields: {json.dumps(remove_item.get('fields', {}), indent=2)}")
        
        # Ask for confirmation before deleting
        user_input = input(f"  Delete issue #{remove} from the project? (y/n): ")
        if user_input.lower() != 'y':
            print("  Skipping this duplicate pair.")
            continue
        
        # Delete the duplicate item
        remove_item_id = remove_item.get('item_id')
        print(f"  Deleting project item with ID: {remove_item_id}")
        success = delete_project_item(remove_item_id)
        
        if success:
            print(f"  ✅ Successfully deleted duplicate item #{remove}")
        else:
            print(f"  ❌ Failed to delete duplicate item #{remove}")
        
        # Add a small delay to avoid API rate limiting
        time.sleep(1)

def main():
    print("GitHub Project Duplicate Item Merger")
    print("====================================")
    
    # Load project items
    project_items = load_project_items()
    print(f"Loaded {len(project_items)} project items from project_items.json")
    
    # Analyze duplicates
    analyze_duplicates(project_items)
    
    # Merge duplicates
    merge_duplicates(project_items)
    
    print("\n✅ Duplicate item merge process completed")
    print("Please run list-project-items.py again to update the local cache")

if __name__ == "__main__":
    main()