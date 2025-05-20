#!/usr/bin/env python3

"""
This script finds GitHub issues that have not been migrated to the GitHub Project.
It creates a dictionary mapping issue titles to their GitHub issue IDs for missing issues.
"""

import subprocess
import json


# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUM = "2"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"  # Project ID from the main script


def run_command(cmd):
    """Run a shell command and return the output"""
    try:
        result = subprocess.run(
            cmd, check=True, capture_output=True, text=True
        )
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, f"Error: {e.stderr}"


def get_all_github_issues():
    """Get all GitHub issues from the repository"""
    print("Getting all GitHub issues...")
    success, output = run_command([
        "gh", "issue", "list",
        "--repo", f"{OWNER}/{REPO}",
        "--limit", "200",  # Increased limit to capture more issues
        "--json", "number,title,labels,state"
    ])

    if success:
        issues = json.loads(output)
        user_stories = {}
        epics = []
        
        print(f"Total issues fetched: {len(issues)}")
        
        # Filter out epics, only keep user stories
        for issue in issues:
            is_epic = any(label.get("name") == "epic" for label in issue.get("labels", []))
            if is_epic:
                epics.append({
                    "id": str(issue["number"]),
                    "title": issue["title"]
                })
            else:
                user_stories[issue["title"]] = str(issue["number"])
                print(f"User story: #{issue['number']} - {issue['title']}")
        
        print(f"Found {len(user_stories)} user stories and {len(epics)} epics in GitHub")
        return user_stories
    else:
        print(f"Failed to get GitHub issues: {output}")
        return {}


def get_all_project_items():
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
                }
              }
              content {
                ... on Issue {
                  title
                  number
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
            return {}
    
    print(f"Total project items fetched: {len(all_nodes)}")
    
    user_stories = {}
    epics = []
    
    for node in all_nodes:
        content = node.get("content", {})
        if not content or content.get("repository", {}).get("name") != REPO:
            continue
            
        # Check if this is a user story or epic
        field_values = node.get("fieldValues", {}).get("nodes", [])
        is_epic = False
        
        for field_value in field_values:
            if (field_value.get("field", {}).get("name") == "Type" and 
                field_value.get("name") == "Epic"):
                is_epic = True
                break
        
        if is_epic:
            epics.append({
                "id": str(content.get("number")),
                "title": content.get("title")
            })
        else:
            # Assume it's a user story if not an epic
            user_stories[content.get("title")] = str(content.get("number"))
            print(f"Project user story: #{content.get('number')} - {content.get('title')}")
    
    print(f"Found {len(user_stories)} user stories and {len(epics)} epics in GitHub Project")
    return user_stories


def find_missing_issues():
    """Find issues that are in GitHub but not in the Project"""
    github_issues = get_all_github_issues()
    project_items = get_all_project_items()
    
    missing_issues = {}
    
    for title, issue_id in github_issues.items():
        if title not in project_items:
            missing_issues[title] = issue_id
    
    # Compare based on issue ID values
    github_issue_ids = set(github_issues.values())
    project_issue_ids = set(project_items.values())
    
    print("\n=== Comparing by Issue ID ===")
    print(f"GitHub issue IDs count: {len(github_issue_ids)}")
    print(f"Project issue IDs count: {len(project_issue_ids)}")
    
    # Find issues that are in GitHub but not in Project by ID
    missing_by_id = github_issue_ids - project_issue_ids
    print(f"Found {len(missing_by_id)} issues missing by ID: {sorted(list(missing_by_id))}")
    
    # Find issues that are in Project but not in GitHub by ID
    extra_by_id = project_issue_ids - github_issue_ids
    print(f"Found {len(extra_by_id)} issues in Project but not in GitHub by ID: {sorted(list(extra_by_id))}")
    
    print(f"\nFound {len(missing_issues)} user stories missing from GitHub Project (by title):")
    
    if missing_issues:
        print("\nMissing User Stories (Title -> GitHub Issue ID):")
        for title, issue_id in missing_issues.items():
            print(f"  '{title}' -> '{issue_id}'")
    else:
        print("No missing user stories found!")
        
    return missing_issues


if __name__ == "__main__":
    missing_issues = find_missing_issues()
    
    # Write the result to a file for easy use
    with open("missing_issues.json", "w") as f:
        json.dump(missing_issues, f, indent=2)
    
    print(f"\nResults written to missing_issues.json")