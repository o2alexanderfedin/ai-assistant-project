# Solo Development Workflow

## Overview

This rule defines the workflow for solo development, eliminating the need for pull requests while maintaining the benefits of the Gitflow branching model.

## Workflow Steps

1. Create feature branches from `develop`
2. Implement changes in feature branches
3. Commit changes with descriptive messages
4. Directly merge feature branches into `develop` using `--no-ff` (no fast-forward)
5. Push changes to remote repository
6. Optionally, delete feature branches after merging

## Merging Feature Branches

```bash
# After completing work on a feature branch
git checkout develop
git merge --no-ff feature/your-feature-name -m "Merge feature/your-feature-name into develop"
git push origin develop
```

## Creating Releases

1. Create release branch from `develop`
2. Bump version numbers
3. Directly merge release branch to `main`
4. Create version tag
5. Merge back into `develop`

```bash
# Creating a release
git checkout -b release/vX.Y.Z develop
# Update version info
git commit -am "Bump version to X.Y.Z"
git checkout main
git merge --no-ff release/vX.Y.Z -m "Release vX.Y.Z"
git tag -a vX.Y.Z -m "Version X.Y.Z"
git checkout develop
git merge --no-ff release/vX.Y.Z -m "Merge release/vX.Y.Z back into develop"
git push --all
git push --tags
```

## Hotfixes

For critical fixes to production:

1. Create hotfix branch from `main`
2. Fix issue and bump version
3. Merge to both `main` and `develop`

---

🧭 **Navigation**:
[Home](/README.md) | [Rules Home](../.claude/rules/README.md)

Last updated: May 20, 2025