#!/usr/bin/env python3

"""
This script migrates the lower-numbered duplicate issues to the GitHub Project.
It takes the mapping from duplicate_issues.json and adds the lower-numbered issues
to the GitHub Project.
"""

import subprocess
import json
import os

# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUM = "2"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"  # Project ID


def run_command(cmd):
    """Run a shell command and return the output"""
    try:
        result = subprocess.run(
            cmd, check=True, capture_output=True, text=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"


def get_field_info():
    """Get field info for the project"""
    print("Getting field information...")
    
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
        
        field_info = {
            "type_field_id": None,
            "type_options": {},
            "priority_field_id": None,
            "priority_options": {},
            "component_field_id": None,
            "component_options": {},
            "story_points_field_id": None
        }
        
        for field in fields:
            field_name = field.get("name")
            if field_name == "Type":
                field_info["type_field_id"] = field.get("id")
                for option in field.get("options", []):
                    field_info["type_options"][option.get("name")] = option.get("id")
            elif field_name == "Priority":
                field_info["priority_field_id"] = field.get("id")
                for option in field.get("options", []):
                    field_info["priority_options"][option.get("name")] = option.get("id")
            elif field_name == "Component":
                field_info["component_field_id"] = field.get("id")
                for option in field.get("options", []):
                    field_info["component_options"][option.get("name")] = option.get("id")
            elif field_name == "Story Points" and field.get("dataType") == "NUMBER":
                field_info["story_points_field_id"] = field.get("id")
        
        return field_info
    else:
        print(f"Failed to get field information: {output}")
        return None


def add_issue_to_project(issue_id, field_info):
    """Add an issue to the project"""
    print(f"Adding issue #{issue_id} to the project...")
    
    # Step 1: Add the issue to the project
    add_query = """
    mutation($projectId:ID!, $contentId:ID!) {
      addProjectV2ItemById(input: {
        projectId: $projectId
        contentId: $contentId
      }) {
        item {
          id
        }
      }
    }
    """
    
    # Get the global ID for the issue
    success, issue_output = run_command([
        "gh", "api", f"repos/{OWNER}/{REPO}/issues/{issue_id}"
    ])
    
    if not success:
        print(f"Failed to get issue information: {issue_output}")
        return False, None
    
    issue_data = json.loads(issue_output)
    issue_node_id = issue_data.get("node_id")
    
    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={add_query}",
        "-f", f"projectId={PROJECT_ID}",
        "-f", f"contentId={issue_node_id}"
    ])
    
    if not success:
        print(f"Failed to add issue to project: {output}")
        return False, None
    
    data = json.loads(output)
    item_id = data.get("data", {}).get("addProjectV2ItemById", {}).get("item", {}).get("id")
    
    if not item_id:
        print(f"Failed to get item ID after adding issue to project")
        return False, None
    
    print(f"Successfully added issue #{issue_id} to project with item ID {item_id}")
    
    # Step 2: Set the Type field to "User Story"
    if field_info["type_field_id"] and "User Story" in field_info["type_options"]:
        print(f"Setting Type field to 'User Story' for issue #{issue_id}...")
        type_query = """
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
            "-f", f"query={type_query}",
            "-f", f"projectId={PROJECT_ID}",
            "-f", f"itemId={item_id}",
            "-f", f"fieldId={field_info['type_field_id']}",
            "-f", f"optionId={field_info['type_options']['User Story']}"
        ])
        
        if not success:
            print(f"Failed to set Type field: {output}")
    
    return True, item_id


def migrate_duplicate_issues():
    """Migrate the lower-numbered duplicate issues to the project"""
    # Check if the duplicate_issues.json file exists
    if not os.path.exists("duplicate_issues.json"):
        print("duplicate_issues.json not found. Please run find_duplicate_issues.py first.")
        return False
    
    # Load the duplicate issues
    with open("duplicate_issues.json", "r") as f:
        duplicates = json.load(f)
    
    # Get field information
    field_info = get_field_info()
    if not field_info:
        print("Failed to get field information")
        return False
    
    # Process each duplicate
    for title, ids in duplicates.items():
        github_ids = ids["github_ids"]
        project_ids = ids["project_ids"]
        
        # Find the lower-numbered GitHub IDs that aren't in the project
        missing_ids = [id for id in github_ids if id not in project_ids]
        
        for issue_id in missing_ids:
            print(f"Migrating issue #{issue_id} '{title}' to the project...")
            success, item_id = add_issue_to_project(issue_id, field_info)
            if success:
                print(f"Successfully migrated issue #{issue_id}")
            else:
                print(f"Failed to migrate issue #{issue_id}")
    
    return True


if __name__ == "__main__":
    print("Starting migration of duplicate issues...")
    success = migrate_duplicate_issues()
    
    if success:
        print("\nMigration completed successfully")
    else:
        print("\nMigration failed")