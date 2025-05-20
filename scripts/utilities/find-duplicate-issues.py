#!/usr/bin/env python3

"""
This script identifies duplicated user stories between GitHub Issues and GitHub Project.
It creates a mapping showing where the same title appears with different issue numbers.
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
                # Store as title -> list of IDs
                title = issue["title"]
                issue_id = str(issue["number"])
                
                if title not in user_stories:
                    user_stories[title] = []
                user_stories[title].append(issue_id)
        
        # Count total user stories
        total_issues = sum(len(ids) for ids in user_stories.values())
        print(f"Found {total_issues} user stories across {len(user_stories)} unique titles and {len(epics)} epics in GitHub")
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
            # Store as title -> list of IDs
            title = content.get("title")
            issue_id = str(content.get("number"))
            
            if title not in user_stories:
                user_stories[title] = []
            user_stories[title].append(issue_id)
    
    # Count total user stories
    total_issues = sum(len(ids) for ids in user_stories.values())
    print(f"Found {total_issues} user stories across {len(user_stories)} unique titles and {len(epics)} epics in GitHub Project")
    return user_stories


def find_duplicate_issues():
    """Find duplicated issues between GitHub and the Project"""
    github_issues = get_all_github_issues()
    project_items = get_all_project_items()
    
    # Create a dictionary to store duplicates (title -> {github_ids: [...], project_ids: [...]})
    duplicates = {}
    
    # Find titles that exist in both GitHub and Project
    common_titles = set(github_issues.keys()) & set(project_items.keys())
    
    for title in common_titles:
        github_ids = github_issues[title]
        project_ids = project_items[title]
        
        # If the issue exists with different IDs in GitHub and Project, it's a duplicate
        if set(github_ids) != set(project_ids):
            duplicates[title] = {
                "github_ids": github_ids,
                "project_ids": project_ids
            }
    
    # Print duplicates in a readable format
    print(f"\nFound {len(duplicates)} user stories with different IDs in GitHub Issues vs GitHub Project:")
    
    if duplicates:
        print("\nDuplicate User Stories (Title -> {GitHub IDs} vs {Project IDs}):")
        for title, ids in duplicates.items():
            print(f"  '{title}':")
            print(f"    - GitHub IDs: {', '.join(ids['github_ids'])}")
            print(f"    - Project IDs: {', '.join(ids['project_ids'])}")
    else:
        print("No duplicate user stories found!")
        
    return duplicates


if __name__ == "__main__":
    duplicates = find_duplicate_issues()
    
    # Write the result to a file for easy use
    with open("duplicate_issues.json", "w") as f:
        json.dump(duplicates, f, indent=2)
    
    print(f"\nResults written to duplicate_issues.json")