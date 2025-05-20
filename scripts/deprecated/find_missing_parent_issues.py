#!/usr/bin/env python3

"""
This script identifies user stories in the GitHub Project that don't have parent issues,
priorities, or story points assigned.
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
            "parent_field_id": None,
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
            elif field_name == "Parent Issue":
                field_info["parent_field_id"] = field.get("id")
            elif field_name == "Story Points" and field.get("dataType") == "NUMBER":
                field_info["story_points_field_id"] = field.get("id")
        
        return field_info
    else:
        print(f"Failed to get field information: {output}")
        return None


def get_all_project_items(field_info):
    """Get all items from the GitHub Project"""
    print("Getting all GitHub Project items...")
    
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
    
    user_stories = []
    
    for node in all_nodes:
        content = node.get("content", {})
        if not content or content.get("repository", {}).get("name") != REPO:
            continue
            
        # Check if this is a user story
        is_user_story = False
        has_parent = False
        has_priority = False
        has_story_points = False
        priority_value = None
        story_points_value = None
        
        field_values = node.get("fieldValues", {}).get("nodes", [])
        for field_value in field_values:
            field_name = field_value.get("field", {}).get("name")
            
            if field_name == "Type" and field_value.get("name") == "User Story":
                is_user_story = True
            
            if field_name == "Parent Issue" and field_value.get("text"):
                has_parent = True
            
            if field_name == "Priority" and field_value.get("name"):
                has_priority = True
                priority_value = field_value.get("name")
            
            if field_name == "Story Points" and field_value.get("number") is not None:
                has_story_points = True
                story_points_value = field_value.get("number")
        
        if is_user_story:
            user_story = {
                "project_item_id": node.get("id"),
                "issue_id": content.get("id"),
                "issue_number": content.get("number"),
                "title": content.get("title"),
                "has_parent": has_parent,
                "has_priority": has_priority,
                "has_story_points": has_story_points,
                "priority": priority_value,
                "story_points": story_points_value
            }
            user_stories.append(user_story)
    
    return user_stories


def find_missing_fields():
    """Find user stories missing parent issues, priorities, or story points"""
    field_info = get_field_info()
    if not field_info:
        print("Failed to get field information")
        return []
    
    user_stories = get_all_project_items(field_info)
    
    missing_parent = []
    missing_priority = []
    missing_story_points = []
    
    for story in user_stories:
        if not story["has_parent"]:
            missing_parent.append(story)
        
        if not story["has_priority"]:
            missing_priority.append(story)
        
        if not story["has_story_points"]:
            missing_story_points.append(story)
    
    return {
        "missing_parent": missing_parent,
        "missing_priority": missing_priority,
        "missing_story_points": missing_story_points,
        "field_info": field_info,
        "all_user_stories": user_stories
    }


def get_issue_details(issue_number):
    """Get details for a specific issue from GitHub"""
    success, output = run_command([
        "gh", "issue", "view", str(issue_number),
        "--repo", f"{OWNER}/{REPO}",
        "--json", "title,body,labels"
    ])
    
    if success:
        return json.loads(output)
    else:
        print(f"Failed to get issue details for issue #{issue_number}: {output}")
        return None


def print_report(results):
    """Print a report of the findings"""
    all_user_stories = results["all_user_stories"]
    missing_parent = results["missing_parent"]
    missing_priority = results["missing_priority"]
    missing_story_points = results["missing_story_points"]
    
    print("\n===== REPORT =====")
    print(f"Total User Stories: {len(all_user_stories)}")
    print(f"Missing Parent Issues: {len(missing_parent)}")
    print(f"Missing Priorities: {len(missing_priority)}")
    print(f"Missing Story Points: {len(missing_story_points)}")
    
    if missing_parent:
        print("\n--- User Stories Missing Parent Issues ---")
        for story in missing_parent:
            print(f"#{story['issue_number']} - {story['title']}")
    
    if missing_priority:
        print("\n--- User Stories Missing Priorities ---")
        for story in missing_priority:
            print(f"#{story['issue_number']} - {story['title']}")
    
    if missing_story_points:
        print("\n--- User Stories Missing Story Points ---")
        for story in missing_story_points:
            print(f"#{story['issue_number']} - {story['title']}")


if __name__ == "__main__":
    print("Finding user stories with missing fields...")
    results = find_missing_fields()
    
    if results:
        print_report(results)
        
        # Write the results to a file for the migration script to use
        with open("missing_fields.json", "w") as f:
            json.dump(results, f, indent=2)
        
        print("\nResults written to missing_fields.json")
    else:
        print("Failed to analyze project fields. Please check the error messages above.")