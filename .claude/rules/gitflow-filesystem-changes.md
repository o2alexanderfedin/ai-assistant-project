# Gitflow For Filesystem Changes

## Problem
When making changes to files on the filesystem, creating multiple copies of files leads to:
- Duplicate files with slightly different content
- Confusion about which version is current/canonical
- Difficulty tracking changes and history
- Accumulation of unused backup files
- Increased disk usage and maintenance burden

## Solution
Always use Git and follow the Gitflow workflow for any changes that touch the filesystem:

1. **Create feature branch** for the changes
2. **Make changes directly in-place** within the branch
3. **Commit changes** with descriptive messages
4. **Create pull request** for review
5. **Merge changes** only after review

This approach maintains a clear history and allows for easy rollbacks without creating duplicate files.

### Working Example
```bash
# Start with a feature branch
git checkout develop
git checkout -b feature/reorganize-scripts

# Make changes directly to files (don't create copies!)
mv old_location/script.sh new_location/script.sh
edit new_location/script.sh  # Edit the file in-place

# Commit the changes
git add -A
git commit -m "Reorganize scripts and update paths"

# Push and create PR
git push origin feature/reorganize-scripts
# Create PR on GitHub for review
```

## Common Errors

### "I'll make a backup copy just in case"
Instead of creating backup copies like `script.sh.bak` or `script.sh.old`, use Git's versioning:
```bash
# If you need to revert later:
git checkout -- path/to/script.sh  # Discard changes in working directory
# or
git reset HEAD~1  # Undo the last commit but keep changes
# or
git revert HEAD  # Create a new commit that undoes the last commit
```

### "I need to try different approaches"
Instead of creating multiple copies with different approaches, use branches:
```bash
# Create branches for different approaches
git checkout -b approach1
# Make changes, test
git checkout -b approach2
# Make different changes, test
# Then choose the best approach to merge
```

## Notes
- When refactoring, moving, or renaming files, use Git's commands to track these changes:
  ```bash
  git mv old_path new_path  # Records the move/rename in Git
  ```
- Always commit logical units of work with descriptive commit messages
- For temporary exploratory changes, use Git stash:
  ```bash
  git stash  # Save current changes
  # Do something else
  git stash pop  # Restore the changes
  ```
- Remember that Git tracks content, not files, so even after renaming, history is preserved

## References
- [Gitflow Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Git Basics](https://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository)