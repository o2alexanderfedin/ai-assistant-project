#!/usr/bin/env python3

import subprocess
import json
import time
import sys
import re
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

def get_all_github_issues() -> List[Dict[str, Any]]:
    """Get all GitHub issues with their fields"""
    print("🔍 Getting all GitHub issues...")
    success, output = run_command([
        "gh", "issue", "list", 
        "--repo", f"{OWNER}/{REPO}", 
        "--limit", "100", 
        "--json", "number,title,body,labels,comments,assignees,milestone"
    ])
    
    if success:
        return json.loads(output)
    else:
        print(output)
        return []

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

def get_issue_node_id(issue_number: str) -> Optional[str]:
    """Get the node ID for a GitHub issue"""
    success, output = run_command([
        "gh", "issue", "view", issue_number,
        "--repo", f"{OWNER}/{REPO}",
        "--json", "id"
    ])
    
    if success:
        return json.loads(output).get("id")
    else:
        print(f"Failed to get node ID for issue #{issue_number}")
        print(output)
        return None

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
            if content and int(content.get("number", 0)) == int(issue_number):
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
    
    # Get the parent and child node IDs
    parent_id = get_issue_node_id(parent_num)
    child_id = get_issue_node_id(child_num)
    
    if not parent_id or not child_id:
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
    
    if success and "duplicate sub-issues" not in output:
        if "errors" not in output.lower():
            print(f"  ✅ Successfully set parent relationship")
            return True
        else:
            print(f"  ❌ Failed to set parent relationship")
            print(output)
            return False
    else:
        print(f"  ℹ️ Relationship already exists or error occurred")
        return True  # Consider it a success if relationship already exists

def migrate_issue_comments(issue_number: str, comments: List[Dict[str, Any]]) -> bool:
    """Migrate comments from GitHub issue to project notes (if applicable)"""
    if not comments:
        return True  # No comments to migrate
    
    print(f"  Migrating {len(comments)} comments for issue #{issue_number}...")
    
    # Project notes are not directly supported by the GitHub CLI
    # Comments would need to be added as notes to the project item
    # This is often done through the UI or using custom API calls
    
    # For now, we'll just log that we would migrate these comments
    for i, comment in enumerate(comments):
        author = comment.get("author", {}).get("login", "unknown")
        body = comment.get("body", "")
        created_at = comment.get("createdAt", "")
        
        print(f"  Comment {i+1} by {author} on {created_at}:")
        print(f"  {body[:50]}..." if len(body) > 50 else f"  {body}")
    
    print(f"  ℹ️ Comment migration requires manual copying to project notes")
    return True

def process_issue(issue: Dict[str, Any], project_items: List[Dict[str, Any]], fields: Dict[str, Any]) -> None:
    """Process a single GitHub issue, ensuring it's in the project with all fields"""
    issue_number = str(issue.get("number"))
    issue_title = issue.get("title")
    
    print(f"Processing issue #{issue_number}: '{issue_title}'")
    
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
    
    # Migrate comments
    migrate_issue_comments(issue_number, issue.get("comments", []))
    
    print("")  # Add a blank line for readability

def main():
    """Main function to orchestrate the migration process"""
    print("Starting comprehensive GitHub issue migration...")
    
    # Get all GitHub issues
    github_issues = get_all_github_issues()
    if not github_issues:
        print("No GitHub issues found or error occurred.")
        return
    
    print(f"Found {len(github_issues)} issues in GitHub repository.")
    
    # Get all project items
    project_items = get_all_project_items()
    print(f"Found {len(project_items)} items in GitHub project.")
    
    # Get project fields
    fields = get_project_fields()
    if not fields:
        print("Failed to retrieve project fields. Cannot proceed.")
        return
    
    # Process each issue
    for issue in github_issues:
        process_issue(issue, project_items, fields)
    
    print("🏁 Finished comprehensive migration of all issues!")
    print("All issues should now be in the project with correct types and parent relationships.")

if __name__ == "__main__":
    main()