# Field Management Scripts

This directory contains scripts for managing custom fields in GitHub Projects.

## Scripts

| Script | Description |
|--------|-------------|
| `create-fields.sh` | Creates all custom fields in the project |
| `create-component-field.sh` | Creates the Component field with options |
| `create-epic-field.sh` | Creates the Epic field |
| `set-components.sh` | Sets Component field values |
| `update-missing-components.py` | Updates missing Component field values |
| `set-types.sh` | Sets Type field values |
| `set-story-points.py` | Sets Story Points field values |
| `update-parent-and-points.py` | Updates both Parent and Story Points fields |

## Usage

### Creating All Fields

```bash
./create-fields.sh
```

### Setting Type Field Values

```bash
./set-types.sh
```

### Setting Component Field Values

```bash
./set-components.sh
```

### Setting Story Points

```bash
python set-story-points.py
```
