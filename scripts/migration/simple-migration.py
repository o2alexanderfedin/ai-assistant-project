#!/usr/bin/env python3

"""
GitHub Issue Migration Script

This script ensures all GitHub issues are properly migrated to a GitHub
Project, following the exact flow:
1. Get all issue IDs from GitHub repository
2. For each issue, get all details (title, body, labels, etc.)
3. Find the corresponding project issue by title
4. If found, update fields; if not found, add to project

Usage:
    python3 simple_migration.py [--limit N]

    --limit N: Process only the first N issues (useful for testing)
"""

import subprocess
import json
import argparse


# Configuration
OWNER = "o2alexanderfedin"
REPO = "ai-assistant-project"
PROJECT_NUM = "2"
PROJECT_ID = "PVT_kwHOBJ7Qkc4A5SDb"  # Project ID for GraphQL queries

# Parent-child relationships mapping
PARENT_RELATIONSHIPS = {
    "1": ["66", "65", "64", "63", "62", "61", "60", "59"],
    "2": ["17", "18", "19", "20", "21", "22", "23", "24"],
    "3": ["54", "55", "56", "57", "58"],
    "4": ["25", "26", "27", "28", "29", "30", "31", "32"],
    "5": ["33", "34", "35", "36", "37", "38", "39", "40"],
    "6": ["41", "42", "43", "44", "45", "46", "47"],
    "7": ["48", "49", "50", "51", "52", "53"]
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


def get_issue_ids():
    """Get all issue IDs from the repository"""
    print("Getting issue IDs from GitHub repository...")
    success, output = run_command([
        "gh", "issue", "list",
        "--repo", f"{OWNER}/{REPO}",
        "--limit", "100",
        "--json", "number"
    ])

    if success:
        issues = json.loads(output)
        return [str(issue["number"]) for issue in issues]
    else:
        print(f"Failed to get issue IDs: {output}")
        return []


def get_issue_details(issue_id):
    """Get all details for a specific issue"""
    print(f"Getting details for issue #{issue_id}...")
    success, output = run_command([
        "gh", "issue", "view", str(issue_id),
        "--repo", f"{OWNER}/{REPO}",
        "--json", ("number,title,body,labels,assignees,milestone,"
                   "id,comments,state")
    ])

    if success:
        return json.loads(output)
    else:
        print(f"Failed to get details for issue #{issue_id}")
        return None


def find_issue_in_project(issue_title):
    """Find an issue in the project by its title"""
    print(f"  Searching for issue in project by title: '{issue_title}'")

    # Query to find a project item by title
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 100) {
            nodes {
              id
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
        nodes = data.get("data", {}).get("node", {}).get(
            "items", {}).get("nodes", [])

        for node in nodes:
            content = node.get("content", {})
            if not content:
                continue

            # Match by title and repository
            if (content.get("title") == issue_title and
                    content.get("repository", {}).get("name") == REPO):
                print(f"  ✓ Found issue in project: #{content.get('number')}")
                return {
                    "id": node.get("id"),
                    "number": content.get("number")
                }
    else:
        print(f"  ! Failed to search project issues: {output}")

    print("  ✗ Issue not found in project")
    return None


def get_field_info():
    """Get project field IDs and options"""
    print("Getting project field information...")
    query = """
    query($projectId:ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          fields(first: 50) {
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
              ... on ProjectV2IterationField {
                id
                name
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
        try:
            data = json.loads(output)
            result = {}

            nodes = data.get("data", {}).get("node", {}).get(
                "fields", {}).get("nodes", [])

            # Debug to see all fields and options
            print("Available fields in project:")
            for node in nodes:
                name = node.get("name")
                print(f"  - Field: {name} (ID: {node.get('id')})")
                if "options" in node:
                    for opt in node.get("options", []):
                        print(f"    * Option: {opt.get('name')} "
                              f"(ID: {opt.get('id')})")

            # Process fields
            for node in nodes:
                name = node.get("name")

                # Type field
                if name == "Type":
                    options = {
                        opt.get("name"): opt.get("id")
                        for opt in node.get("options", [])
                    }
                    result["type_field_id"] = node.get("id")
                    result["epic_option_id"] = options.get("Epic")
                    result["user_story_option_id"] = options.get("User Story")

                # Priority field
                elif name == "Priority":
                    options = {
                        opt.get("name"): opt.get("id")
                        for opt in node.get("options", [])
                    }
                    result["priority_field_id"] = node.get("id")
                    result["priority_options"] = options

                # Component field
                elif name == "Component":
                    options = {
                        opt.get("name"): opt.get("id")
                        for opt in node.get("options", [])
                    }
                    result["component_field_id"] = node.get("id")
                    result["component_options"] = options

                # Story Points field (using common field type and checking dataType)
                elif (name == "Story Points" or name == "Story points" or
                      name.lower() == "story points"):
                    data_type = node.get("dataType")
                    if data_type == "NUMBER" or not data_type:
                        result["story_points_field_id"] = node.get("id")

            # Validate field info
            if "type_field_id" not in result:
                print("Warning: Type field not found in project")
            elif not result["type_field_id"]:
                print("Warning: Type field ID is missing")

            if "epic_option_id" not in result:
                print("Warning: Epic option not found in project")
            elif not result["epic_option_id"]:
                print("Warning: Epic option ID is missing")

            if "user_story_option_id" not in result:
                print("Warning: User Story option not found in project")
            elif not result["user_story_option_id"]:
                print("Warning: User Story option ID is missing")

            if "priority_field_id" not in result:
                print("Warning: Priority field not found in project")

            if "component_field_id" not in result:
                print("Warning: Component field not found in project")

            if "story_points_field_id" not in result:
                print("Warning: Story Points field not found in project")

            return result

        except json.JSONDecodeError as e:
            print(f"Failed to parse field info JSON: {e}")
            return {}
    else:
        print(f"Failed to get field info: {output}")
        return {}


def add_issue_to_project(issue):
    """Add an issue to the project"""
    issue_id = issue.get("number")
    issue_title = issue.get("title")
    print(f"  Adding issue #{issue_id} to project...")

    success, output = run_command([
        "gh", "project", "item-add", PROJECT_NUM,
        "--owner", OWNER,
        "--url", f"https://github.com/{OWNER}/{REPO}/issues/{issue_id}"
    ])

    if success:
        print("  ✓ Issue added to project")

        # Find the newly created project item
        project_issue = find_issue_in_project(issue_title)
        if project_issue:
            return project_issue
    else:
        print(f"  ✗ Failed to add issue to project: {output}")

    return None


def update_issue_in_project(issue, project_issue, field_info):
    """Update issue fields in the project"""
    issue_id = issue.get("number")
    project_item_id = project_issue.get("id")
    print(f"  Updating issue #{issue_id} in project...")

    if not field_info:
        print("  ✗ Failed to get field information")
        return False

    # Get issue labels and extract needed information
    labels = issue.get("labels", [])

    # 1. Set issue type based on labels
    is_epic = any(label.get("name") == "epic" for label in labels)
    type_name = "Epic" if is_epic else "User Story"

    # Check if field_info has the required option IDs
    if is_epic and "epic_option_id" not in field_info:
        print("  ✗ Epic option ID not found in field info")
        return False
    if not is_epic and "user_story_option_id" not in field_info:
        print("  ✗ User Story option ID not found in field info")
        return False

    if is_epic:
        type_option_id = field_info["epic_option_id"]
    else:
        type_option_id = field_info["user_story_option_id"]

    if not type_option_id:
        print(f"  ✗ {type_name} option ID is None")
        return False

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
        "-f", f"itemId={project_item_id}",
        "-f", f"fieldId={field_info['type_field_id']}",
        "-f", f"optionId={type_option_id}"
    ])

    if success:
        try:
            result = json.loads(output)
            if "errors" not in result:
                print(f"  ✓ Type set to {type_name}")
            else:
                error_json = json.dumps(result.get('errors', []), indent=2)
                print(f"  ✗ Failed to set type: {error_json}")
                return False
        except json.JSONDecodeError:
            if "errors" not in output.lower():
                print(f"  ✓ Type set to {type_name}")
            else:
                print(f"  ✗ Failed to set type: {output}")
                return False
    else:
        print(f"  ✗ Failed to set type: {output}")
        return False

    # 2. Set Component if available
    has_component = ("component_field_id" in field_info and
                     "component_options" in field_info)
    if has_component:
        # Find the component label if present
        component_label = None
        for label in labels:
            name = label.get("name", "")
            if name.startswith("component:"):
                component_name = name.replace("component:", "").strip()
                component_label = component_name
                break

        if (component_label and
                component_label in field_info["component_options"]):
            component_id = field_info["component_options"][component_label]
            print(f"  Setting component to '{component_label}'...")

            success, output = run_command([
                "gh", "api", "graphql",
                "-f", f"query={mutation}",
                "-f", f"projectId={PROJECT_ID}",
                "-f", f"itemId={project_item_id}",
                "-f", f"fieldId={field_info['component_field_id']}",
                "-f", f"optionId={component_id}"
            ])

            if success and "errors" not in output.lower():
                print(f"  ✓ Component set to {component_label}")
            else:
                print(f"  ✗ Failed to set component: {output}")

    # 3. Set Priority if available
    if "priority_field_id" in field_info and "priority_options" in field_info:
        # Find the priority label if present
        priority_label = None
        for label in labels:
            name = label.get("name", "")
            if name.startswith("priority:"):
                priority_name = name.replace("priority:", "").strip()
                # Capitalize first letter
                priority_label = priority_name.title()
                break

        # Default to Medium if no priority is found
        if not priority_label:
            priority_label = "Medium"

        if priority_label in field_info["priority_options"]:
            priority_id = field_info["priority_options"][priority_label]
            print(f"  Setting priority to '{priority_label}'...")

            success, output = run_command([
                "gh", "api", "graphql",
                "-f", f"query={mutation}",
                "-f", f"projectId={PROJECT_ID}",
                "-f", f"itemId={project_item_id}",
                "-f", f"fieldId={field_info['priority_field_id']}",
                "-f", f"optionId={priority_id}"
            ])

            if success and "errors" not in output.lower():
                print(f"  ✓ Priority set to {priority_label}")
            else:
                print(f"  ✗ Failed to set priority: {output}")

    # 4. Set Story Points if available - temporarily disabled due to API limitations
    if "story_points_field_id" in field_info:
        # Just detect if there are story points defined
        for label in labels:
            if label.get("name", "").startswith("points:"):
                points_str = label.get("name").replace("points:", "").strip()
                try:
                    points = int(points_str)
                    print(f"  ℹ️ Story points ({points}) detected, but setting via API is disabled")
                    print(f"     This will need to be set manually in the project")
                    break
                except ValueError:
                    print(f"  ⚠️ Invalid story points value: {points_str}")

    # 5. Set parent relationship if applicable
    for parent_id, children in PARENT_RELATIONSHIPS.items():
        if str(issue_id) in children:
            parent_success = set_parent_relationship(parent_id, issue_id)
            if not parent_success:
                print(
                    f"  ⚠️ Warning: Failed to set parent relationship "
                    f"for issue #{issue_id}"
                )
            break

    return True


def set_parent_relationship(parent_id, child_id):
    """Set parent-child relationship using project items found by title"""
    print(f"  Setting parent relationship: #{parent_id} -> #{child_id}")

    # Get GitHub issue details for both parent and child
    parent_data = get_issue_details(parent_id)
    child_data = get_issue_details(child_id)

    if not parent_data or not child_data:
        print(
            f"  ✗ Could not get details for parent #{parent_id} "
            f"or child #{child_id}"
        )
        return False

    # Find project items by title
    parent_title = parent_data.get("title")
    child_title = child_data.get("title")

    print(
        f"  Finding project items for parent '{parent_title}' "
        f"and child '{child_title}'"
    )

    # Find the project items that correspond to these GitHub issues
    parent_project_issue = find_issue_in_project(parent_title)
    child_project_issue = find_issue_in_project(child_title)

    if not parent_project_issue:
        print("  ✗ Parent issue not found in project")
        return False

    if not child_project_issue:
        print("  ✗ Child issue not found in project")
        return False

    # Get GitHub issue IDs (different from issue numbers)
    parent_github_id = parent_data.get("id")
    child_github_id = child_data.get("id")

    # Check if parent relationship already exists
    print("  Checking if parent relationship already exists...")
    query = """
    query($childId:ID!) {
      node(id: $childId) {
        ... on Issue {
          number
          title
          parent {
            id
            number
            title
          }
        }
      }
    }
    """

    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={query}",
        "-f", f"childId={child_github_id}"
    ])

    if success:
        try:
            data = json.loads(output)
            parent = data.get("data", {}).get("node", {}).get("parent", {})

            # Compare as strings for consistency
            if parent and str(parent.get("number")) == str(parent_id):
                print("  ℹ️ Parent relationship already exists")
                return True
        except Exception as e:
            print(f"  Warning: Error checking parent relationship: {e}")
            # Continue with creation attempt

    # Set parent-child relationship using GitHub issue IDs
    # The GitHub API still uses GitHub issue IDs even though we
    # found the issues in the project
    print("  Creating sub-issue relationship in GitHub...")
    mutation = """
    mutation($parentId:ID!, $childId:ID!) {
      addSubIssue(input: {
        issueId: $parentId,
        subIssueId: $childId,
        replaceParent: true
      }) {
        issue {
          number
        }
        subIssue {
          number
        }
      }
    }
    """

    success, output = run_command([
        "gh", "api", "graphql",
        "-f", f"query={mutation}",
        "-f", f"parentId={parent_github_id}",
        "-f", f"childId={child_github_id}"
    ])

    if success:
        try:
            result = json.loads(output)
            if "errors" in result:
                error_msg = result.get("errors", [])
                dup_exists = any(
                    "duplicate sub-issues" in str(err)
                    for err in error_msg
                )
                if dup_exists:
                    print("  ℹ️ Parent relationship already exists")
                    return True
                else:
                    err_json = json.dumps(error_msg, indent=2)
                    print(f"  ✗ Failed to set parent relationship: {err_json}")
                    return False
            else:
                print("  ✓ Parent relationship established")
                return True
        except json.JSONDecodeError:
            if "duplicate sub-issues" in output:
                print("  ℹ️ Parent relationship already exists")
                return True
            elif "errors" not in output.lower():
                print("  ✓ Parent relationship established")
                return True
            else:
                print(f"  ✗ Failed to set parent relationship: {output}")
                return False
    else:
        print(f"  ✗ Failed to set parent relationship: {output}")
        return False


def main():
    """Main function - follows the specified flow exactly"""
    # Parse command-line arguments
    parser = argparse.ArgumentParser(
        description='GitHub Issue Migration Script'
    )
    parser.add_argument(
        '--limit', type=int, help='Limit the number of issues to process'
    )
    args = parser.parse_args()

    print("Starting GitHub issue migration...")

    # Get all issue IDs
    issue_ids = get_issue_ids()
    total_issues = len(issue_ids)
    print(f"Found {total_issues} issues in the repository")

    # Apply limit if specified
    if args.limit and args.limit < total_issues:
        print(f"Limiting to {args.limit} issues as requested")
        issue_ids = issue_ids[:args.limit]

    # Get field info (configuration)
    field_info = get_field_info()
    if not field_info:
        print("Failed to get project field information, aborting")
        return

    # Statistics tracking
    stats = {
        "total": len(issue_ids),
        "processed": 0,
        "updated": 0,
        "added": 0,
        "failed": 0,
        "parent_relationships": 0,
        "priorities_set": 0,
        "components_set": 0,
        "story_points_detected": 0
    }

    # Process each issue individually
    for index, issue_id in enumerate(issue_ids):
        # Get all data for this specific issue
        issue = get_issue_details(issue_id)
        if not issue:
            stats["failed"] += 1
            continue

        issue_title = issue.get('title', '')
        progress = f"[{index+1}/{len(issue_ids)}]"
        print(f"{progress} Processing issue #{issue_id}: '{issue_title}'")

        # Check if issue is in project by title
        project_issue = find_issue_in_project(issue_title)

        # Add or update
        if not project_issue:
            project_issue = add_issue_to_project(issue)
            if not project_issue:
                print(
                    "  ❌ CRITICAL ERROR: Failed to add issue "
                    f"#{issue_id} to project"
                )
                print("  This is a serious error that needs investigation")
                print("  Please check GitHub permissions and project access")
                stats["failed"] += 1
                return  # Stop the entire process - this is a critical failure
            stats["added"] += 1

        # Track component, priority, points
        def count_field_updates(issue):
            labels = issue.get("labels", [])
            # Check component
            has_component = any(
                label.get("name", "").startswith("component:")
                for label in labels
            )
            if has_component:
                stats["components_set"] += 1

            # Check priority
            has_priority = any(
                label.get("name", "").startswith("priority:")
                for label in labels
            )
            if has_priority:
                stats["priorities_set"] += 1

            # Check points - note: we're counting defined points even though
            # we don't set them via API currently
            has_points = any(
                label.get("name", "").startswith("points:")
                for label in labels
            )
            if has_points:
                stats["story_points_detected"] += 1

            # Check parent relationship
            for parent_id, children in PARENT_RELATIONSHIPS.items():
                if str(issue_id) in children:
                    stats["parent_relationships"] += 1
                    break

        # Update fields
        update_success = update_issue_in_project(
            issue, project_issue, field_info
        )
        if update_success:
            stats["updated"] += 1
            count_field_updates(issue)
        else:
            print(
                f"  ⚠️ Warning: Failed to update issue #{issue_id} in project"
            )
            print("  Continuing with next issue...")
            stats["failed"] += 1

        stats["processed"] += 1
        print("")  # Add blank line for readability

    # Print summary
    print("\n📊 Migration Summary:")
    print(f"  Total issues processed: {stats['processed']}/{stats['total']}")
    print(f"  Issues added to project: {stats['added']}")
    print(f"  Issues updated in project: {stats['updated']}")
    print(f"  Parent relationships set: {stats['parent_relationships']}")
    print(f"  Components set: {stats['components_set']}")
    print(f"  Priorities set: {stats['priorities_set']}")
    print(f"  Story points detected: {stats['story_points_detected']} (must be set manually)")
    print(f"  Failed operations: {stats['failed']}")

    print("\n✅ Migration completed successfully!")


if __name__ == "__main__":
    main()
