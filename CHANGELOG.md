# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2025-05-19

### Added
- Created `.claude/rules/` directory for storing reusable solutions
- Added rule for managing files using moves instead of copies
- Added rule for following gitflow when working with the filesystem
- Added rule for GitHub parent-child relationships
- Added detailed analysis of duplicate user stories in the project
- Established process for resolving project item duplicates

### Changed
- Reorganized scripts into logical directory structure (migration, parent-child, fields, utilities)
- Improved script organization with standardized directory structure
- Enhanced Claude settings with additional allowed commands
- Updated CLAUDE.md to reference rules directory
- Archived obsolete scripts in deprecated directory

### Fixed
- Resolved duplicate user stories in GitHub Project (#59-66 duplicated #9-16)
- Fixed parent-child relationships by using proper GraphQL API headers
- Eliminated redundant items in GitHub Project

[0.5.0]: https://github.com/o2alexanderfedin/ai-assistant-project/releases/tag/0.5.0
[0.4.0]: https://github.com/o2alexanderfedin/ai-assistant-project/releases/tag/0.4.0
[0.3.0]: https://github.com/o2alexanderfedin/ai-assistant-project/releases/tag/0.3.0
[0.2.0]: https://github.com/o2alexanderfedin/ai-assistant-project/releases/tag/0.2.0
[0.1.0]: https://github.com/o2alexanderfedin/ai-assistant-project/releases/tag/0.1.0