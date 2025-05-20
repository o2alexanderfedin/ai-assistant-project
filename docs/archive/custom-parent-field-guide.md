# Custom Parent Field Guide

## 📋 Overview

This guide provides instructions for using a custom "Parent Link" text field as a programmatic alternative to GitHub's built-in parent-child relationship feature.

## 🚫 Why a Custom Field?

GitHub's built-in Parent issue field cannot be set programmatically through the API. After extensive research and testing, we created a workaround using a custom text field that can be:

1. Set programmatically via GitHub's GraphQL API
2. Used to create clickable links to parent issues
3. Used for grouping in project views

## 🛠️ Setup Instructions

### Step 1: Create the Custom Field

1. Go to your GitHub Project: https://github.com/users/o2alexanderfedin/projects/1
2. Click "+ New field" in the table view
3. Name the field "Parent Link"
4. Select "Text" as the field type
5. Click "Save"

### Step 2: Set Up Parent Links

You can use one of two scripts depending on your needs:

#### To set a parent link for an existing issue:

```bash
./scripts/set-parent-link-fixed.sh <child_issue_number> <parent_issue_number>

# Example:
./scripts/set-parent-link-fixed.sh 42 1
```

#### To create a new issue with a parent link:

```bash
./scripts/create-issue-with-parent-link.sh <parent_issue_number> "Title" "Description" "label1,label2"

# Example:
./scripts/create-issue-with-parent-link.sh 1 "Implement feature X" "This implements X" "user-story,priority:high"
```

Both scripts:
- Add the issue to the project if needed
- Create a formatted markdown link to the parent issue
- Set the custom "Parent Link" field programmatically
- Display the item ID and result of the operation

## 👓 Creating Effective Views

### Parent-Child Hierarchy View

1. Go to your project
2. Create a new view (click "New view" button)
3. Select "Table" as the view type
4. Name it "Issues by Parent"
5. Click on "Group" and select "Parent Link"
6. Arrange other columns as needed
7. Save the view

### Filtering Issues Without Parents

1. Create a new view
2. Click "Filter"
3. Select "Parent Link"
4. Choose "is empty"
5. This view will show issues that don't have a parent assigned

## 🔄 Maintaining the System

### Adding New Parent-Child Relationships

When you need to create new parent-child relationships:

1. Use `create-issue-with-parent-link.sh` to create new issues with parents
2. Use `set-parent-link-fixed.sh` to link existing issues 

### Troubleshooting

If you encounter issues:

1. **"Issue not found in project items"**: Ensure the issue is added to the project first
2. **GraphQL errors**: Make sure you're using the correct project ID and field ID in the scripts
3. **Label errors**: Ensure any labels specified exist in the repository

### Benefits of the Custom Field Approach

- **Programmatic Control**: Can be set and updated via the GitHub API
- **Flexibility**: Can link to any issue, not just designated epics
- **Visibility**: Provides clickable links in the project UI
- **Grouping**: Can be used for organization in project views

## 📊 Future Improvements

We'll continue to monitor GitHub's API for improvements that might enable usage of the built-in parent field. Until then, this custom field approach provides a workable alternative with most of the same benefits.

---

🧭 **Navigation**: [Home](/README.md) | [Architecture Documentation](/docs/architecture/README.md)