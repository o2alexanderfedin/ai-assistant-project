#!/usr/bin/env python3

import subprocess
import json
import time
import sys
from typing import Dict, List, Optional, Tuple, Any

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUM = "2"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"

# Parent relationship mapping (epic issue number -> list of child issue numbers)
PARENT_RELATIONSHIPS = {
    "1": ["66", "65", "64", "63", "62", "61", "60", "59"],
    "2": ["17", "18", "19", "20", "21", "22", "23", "24"],
    "3": ["54", "55", "56", "57", "58"],
    "4": ["25", "26", "27", "28", "29", "30", "31", "32"],
    "5": ["33", "34", "35", "36", "37", "38", "39", "40"],
    "6": ["41", "42", "43", "44", "45", "46", "47"],
    "7": ["48", "49", "50", "51", "52", "53"]
}

def run_command(cmd: List[str]) -> Tuple[bool, str]:
    """Run a command and return if it succeeded and the output"""
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"

def get_issue_details(issue_number: str) -> Dict[str, Any]:
    """Get details for a specific GitHub issue"""
    success, output = run_command([
        "gh", "issue", "view", issue_number,
        "--repo", f"{OWNER}/{REPO}",
        "--json", "number,title,body,labels,comments,assignees,milestone,id"
    ])
    
    if success:
        return json.loads(output)
    else:
        print(f"Failed to get details for issue #{issue_number}")
        print(output)
        return {}

def get_project_fields() -> Dict[str, Any]:
    """Get project fields including Type field and its options"""
    print("🔍 Getting project fields...")
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
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
    }
    """
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"projectId={PROJECT_ID}"
    ])
    
    if success:
        data = json.loads(output)
        fields = {}
        
        # Extract all fields
        nodes = data.get("data", {}).get("node", {}).get("fields", {}).get("nodes", [])
        for node in nodes:
            name = node.get("name")
            fields[name] = {
                "id": node.get("id"),
                "options": node.get("options", [])
            }
        
        return fields
    else:
        print("Failed to get project fields")
        print(output)
        return {}

def get_all_project_items() -> List[Dict[str, Any]]:
    """Get all items in the GitHub project"""
    print("🔍 Getting all project items...")
    success, output = run_command(["gh", "project", "item-list", PROJECT_NUM, "--owner", OWNER])
    
    if success:
        # Parse the output to extract item information
        items = []
        lines = output.strip().split('\n')
        for line in lines:
            # Extract issue number and title from the line
            parts = line.split('\t')
            if len(parts) >= 4 and parts[0] == "Issue":
                items.append({
                    "type": parts[0],
                    "title": parts[1],
                    "number": parts[2],
                    "repo": parts[3],
                    "id": parts[4] if len(parts) > 4 else None
                })
        return items
    else:
        print(output)
        return []

def add_issue_to_project(issue_number: str) -> bool:
    """Add an issue to the GitHub project"""
    print(f"  ➕ Adding issue #{issue_number} to project...")
    success, output = run_command([
        "gh", "project", "item-add", PROJECT_NUM,
        "--owner", OWNER,
        "--url", f"https://github.com/{OWNER}/{REPO}/issues/{issue_number}"
    ])
    
    if success:
        print(f"  ✅ Successfully added issue #{issue_number} to project")
        return True
    else:
        print(f"  ❌ Failed to add issue #{issue_number} to project")
        print(output)
        return False

def get_project_item_id(issue_number: str) -> Optional[str]:
    """Get the project item ID for an issue"""
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
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
            if content and str(content.get("number", "")) == str(issue_number):
                return node.get("id")
    
    return None

def set_issue_type(item_id: str, field_id: str, option_id: str, type_name: str) -> bool:
    """Set the type field for an issue in the project"""
    print(f"  Setting type to {type_name}...")
    
    mutation = """
    mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $optionId:String!) {
      updateProjectV2ItemFieldValue(input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { 
          singleSelectOptionId: $optionId
        }
      }) {
        projectV2Item {
          id
        }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={mutation}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"itemId={item_id}",
        "-f", f"fieldId={field_id}",
        "-f", f"optionId={option_id}"
    ])
    
    if success and "errors" not in output.lower():
        print(f"  ✅ Successfully set type to {type_name}")
        return True
    else:
        print(f"  ❌ Failed to set type to {type_name}")
        print(output)
        return False

def set_parent_relationship(parent_num: str, child_num: str) -> bool:
    """Set parent-child relationship between issues"""
    print(f"  Setting parent relationship: Parent #{parent_num} for Child #{child_num}")
    
    # Get the parent issue ID
    parent_issue = get_issue_details(parent_num)
    parent_id = parent_issue.get("id")
    
    # Get the child issue ID
    child_issue = get_issue_details(child_num)
    child_id = child_issue.get("id")
    
    if not parent_id or not child_id:
        print(f"  ❌ Could not get IDs for parent #{parent_num} or child #{child_num}")
        return False
    
    # Set the parent-child relationship
    mutation = """
    mutation($parentId:ID!, $childId:ID!) {
      addSubIssue(input: {
        issueId: $parentId,
        subIssueId: $childId,
        replaceParent: true
      }) {
        issue { number, title }
        subIssue { number, title }
      }
    }
    """
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={mutation}",
        "-f", f"parentId={parent_id}",
        "-f", f"childId={child_id}"
    ])
    
    if success:
        if "duplicate sub-issues" in output:
            print(f"  ℹ️ Relationship already exists")
            return True
        elif "errors" not in output.lower():
            print(f"  ✅ Successfully set parent relationship")
            return True
        else:
            print(f"  ❌ Failed to set parent relationship")
            print(output)
            return False
    else:
        print(f"  ❌ Failed to set parent relationship")
        print(output)
        return False

def process_issue(issue_number: str, project_items: List[Dict[str, Any]], fields: Dict[str, Any]) -> None:
    """Process a single GitHub issue, ensuring it's in the project with all fields"""
    print(f"Processing issue #{issue_number}")
    
    # Get issue details
    issue = get_issue_details(issue_number)
    if not issue:
        print(f"  ⚠️ Could not get details for issue #{issue_number}, skipping")
        return
    
    issue_title = issue.get("title")
    print(f"  Issue title: {issue_title}")
    
    # Get Type field and its options
    type_field = fields.get("Type", {})
    type_field_id = type_field.get("id")
    type_options = {opt.get("name"): opt.get("id") for opt in type_field.get("options", [])}
    
    # Determine if issue is epic or user story
    is_epic = any(label.get("name") == "epic" for label in issue.get("labels", []))
    type_name = "Epic" if is_epic else "User Story"
    type_option_id = type_options.get(type_name)
    
    # Check if issue is already in project
    in_project = False
    for item in project_items:
        if item.get("number") == issue_number or item.get("title") == issue_title:
            in_project = True
            break
    
    # Get or add issue to project
    if in_project:
        print(f"  ✓ Issue already in project")
    else:
        if not add_issue_to_project(issue_number):
            print(f"  ⚠️ Skipping further processing for issue #{issue_number}")
            return
        time.sleep(2)  # Wait for the item to be added
    
    # Get the item ID
    item_id = get_project_item_id(issue_number)
    if not item_id:
        print(f"  ⚠️ Could not find item ID for issue #{issue_number}")
        return
    
    # Set the type
    if type_field_id and type_option_id:
        set_issue_type(item_id, type_field_id, type_option_id, type_name)
    
    # Set parent relationship if this is a child issue
    for parent_num, children in PARENT_RELATIONSHIPS.items():
        if issue_number in children:
            set_parent_relationship(parent_num, issue_number)
            break

def main():
    """Main function to process a batch of issues"""
    if len(sys.argv) < 3:
        print("Usage: python process_issue_batch.py <start_number> <end_number>")
        sys.exit(1)
    
    try:
        start_num = int(sys.argv[1])
        end_num = int(sys.argv[2])
    except ValueError:
        print("Error: Start and end numbers must be integers")
        sys.exit(1)
    
    if start_num > end_num:
        print("Error: Start number must be less than or equal to end number")
        sys.exit(1)
    
    print(f"Processing issues from #{start_num} to #{end_num}...")
    
    # Get project fields
    fields = get_project_fields()
    if not fields:
        print("Failed to retrieve project fields. Cannot proceed.")
        return
    
    # Get all project items
    project_items = get_all_project_items()
    print(f"Found {len(project_items)} items in GitHub project.")
    
    # Process each issue in the specified range
    for issue_num in range(start_num, end_num + 1):
        process_issue(str(issue_num), project_items, fields)
        print("")  # Add a blank line for readability
    
    print(f"🏁 Finished processing issues from #{start_num} to #{end_num}")

if __name__ == "__main__":
    main()