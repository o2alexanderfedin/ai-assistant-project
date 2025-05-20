# File Reorganization Rule

## Problem
When reorganizing files in a codebase (scripts, configuration files, etc.), using `cp` (copy) commands creates duplicate files in multiple locations. This leads to:
- Confusion about which version is current/canonical
- Wasted disk space
- Maintenance issues when updating files
- Potential version conflicts

## Solution
Always use `mv` (move) instead of `cp` (copy) when reorganizing files, unless you specifically need both copies.

### Working Example
```bash
# AVOID (creates duplicates):
cp /path/to/original.sh /new/location/renamed.sh

# PREFER (moves the file to new location):
mv /path/to/original.sh /new/location/renamed.sh
```

For batch operations:
```bash
# For multiple files, use find with -exec mv:
find ./source_dir -name "*.sh" -exec mv {} ./target_dir/ \;

# Or use a for loop with mv:
for file in ./source_dir/*.sh; do
  mv "$file" ./target_dir/
done
```

## Common Errors

### "File not found" after moving
This happens when scripts reference files at their old locations. After moving files, update references to point to the new locations.

### Broken references
When moving files that are referenced by other files, use tools like `grep` to find references and update them.

### Permission denied
Check file permissions before moving. You may need to:
```bash
chmod +x script_to_move.sh  # Make executable
sudo mv script_to_move.sh /new/location/  # Use sudo if needed
```

## Notes
- Always create a backup before major reorganizations
- If needed for documentation/testing, use symbolic links rather than duplicates:
  ```bash
  # Instead of copying, create a symlink:
  ln -s /actual/location/file.sh /reference/location/file.sh
  ```
- For important files that absolutely need to be in multiple places, consider using a configuration management tool rather than maintaining duplicate files
- When writing cleanup/organization scripts, validate that files were successfully moved before proceeding

## References
- [Unix file management best practices](https://en.wikipedia.org/wiki/File_management)
- [GNU Coreutils documentation for mv](https://www.gnu.org/software/coreutils/manual/html_node/mv-invocation.html)