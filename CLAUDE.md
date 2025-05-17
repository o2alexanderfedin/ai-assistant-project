# Documentation Rules

## General Guidelines
- All discussions and decisions should be logged in `./docs/logs/YYYY-MM-DD/topic.md`
- Architecture documents should be maintained in `./docs/architecture/` with proper subdirectories
- This file (CLAUDE.md) will contain process improvements and rules

## Documentation Structure
- `/docs/architecture/components/` - Individual agent components and subsystems
- `/docs/architecture/interfaces/` - Communication protocols and APIs
- `/docs/architecture/diagrams/` - Visual representations of the architecture
- `/docs/architecture/decisions/` - Key architectural decisions and rationales
- `/docs/logs/YYYY-MM-DD/` - Daily logs organized by date and topic

## Document Format Requirements
- Every document must include:
  - 📑 Table of Contents for documents with 3+ sections
  - 🧭 Navigation footer with contextual links (Home, Up, Prev/Next where applicable)
  - Last updated date
  - Emojis for section headers to improve scannability
  - Horizontal rule (---) before navigation footer
- README.md files must exist in each directory to explain its purpose
- Use relative links for all cross-references

## Documentation Process
- Create a new dated directory for each day's logs
- Create topic-specific log files within the dated directory
- Update relevant architecture documents after each session
- Cross-reference logs and architecture documents with relative links
- Regenerate table of contents when document structure changes

## Architecture Documentation
- Begin each document with a clear purpose statement
- Use consistent headings and formatting
- Include table of contents for longer documents
- Use diagrams where appropriate (reference diagram files in the docs)
- Document interfaces between components clearly
- Track decisions and their rationales with dates and references

## Markdown Conventions
- Use `#` for document title (only one per document)
- Use `##` for main sections
- Use `###` for subsections
- Use `####` for component details
- Use backticks for code, paths, and technical terms
- Use *italics* for emphasis
- Use **bold** for warnings or critical information
- Use > blockquotes for notes or quotes
- Use tables for structured data comparison

# Git Workflow Rules

## Repository Management
- The project must be versioned using Git and hosted on GitHub
- A repository should be created on GitHub and kept up-to-date
- All development work must be performed through Git
- Commit messages must be clear and descriptive

## Gitflow Workflow
- All work must follow the Gitflow branching model
- Use `main` branch for stable releases
- Use `develop` branch as the integration branch
- Use feature branches (`feature/feature-name`) for new features
- Use release branches (`release/vX.Y.Z`) for release preparation
- Use hotfix branches (`hotfix/fix-name`) for urgent fixes

## Task Execution Process
- Each task must be worked on in its own feature branch
- Every feature branch must be created from the `develop` branch
- Completed features must be merged back to `develop` via pull requests
- Follow the complete workflow for every task:
  1. Create feature branch
  2. Implement changes
  3. Commit with descriptive messages
  4. Create pull request
  5. Review and merge

## Git Hooks Configuration
- Git hooks must be configured to provide workflow guidance
- Pre-commit hooks should enforce code style and documentation standards
- Post-checkout hooks should display current branch context and next steps
- Pre-push hooks should verify test coverage and linting
- Hooks should print reminders about the current stage and next actions

## Completion Requirement
- All tasks must be followed through to completion
- Never stop at the planning stage without implementation
- Complete all items in task lists before considering work complete
- Document completion status in commit messages and pull requests

# Implementation Rules

## Shell-Based Implementation
- Use shell scripts rather than Python where possible
- Minimize external dependencies
- Follow SOLID, KISS, and DRY principles in all implementations
- Ensure each component has a single responsibility

## Testing Requirements
- Follow Test-Driven Development (TDD) principles
- Write tests before implementing features
- Run appropriate tests after changes
- Document test coverage

## Continuous Execution
- Continue working on tasks until they are fully completed
- Do not stop at planning or partial implementation
- Follow through with all defined steps in the process
- Update documentation to reflect completed work