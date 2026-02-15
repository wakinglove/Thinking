# Job Status & Natural Language Control Script

A bash-based progress reporter with Telegram integration and natural language command support.

## Features

- **Smart Intervals**: First update at 1.5 minutes (90s), then every 3 minutes
- **Telegram Integration**: Automatic progress updates to Telegram
- **Dual Interrupt Modes**: Stop job + reporting, OR stop only updates
- **Natural Language Commands**: "stop process", "stop update", "update now"

## Usage

### Start a Job with Progress Reporting

```bash
bash job-status-control/progress-reporter.sh "Task description" "command"
```

With custom intervals:
```bash
bash job-status-control/progress-reporter.sh "Task" "command" 90 180
# First: 90s, Subsequent: 180s
```

### Control Commands

| Command | Effect |
|---------|--------|
| `bash progress-command.sh "stop process"` | Stop job + reporting |
| `bash progress-command.sh "stop update"` | Stop only updates (job continues) |
| `bash progress-command.sh "update now"` | Send immediate status |
| `bash progress-command.sh "help"` | Show all commands |

### Alternative: File-Based Control

```bash
touch /tmp/progress_interrupt    # Stop job + reporting
touch /tmp/silent_interrupt     # Stop only updates
```

## Default Intervals

- **First update**: 1.5 minutes (90s) - optimized for ~1:15 min image generation
- **Subsequent**: 3 minutes (180s) - for longer processes
- **Interrupt checks**: Every 5 seconds

## Files

- `progress-reporter.sh` - Main script that runs jobs and sends updates
- `progress-interrupt.sh` - File-based interrupt control
- `progress-command.sh` - Natural language command parser

## Telegram Format

Updates are sent in table format:
```
| ⏳ Task Name |
|--------------|
| Elapsed: 1m 30s |
| Status: Running... |
```

## Examples

### Image Generation with Progress

```bash
bash scripts/progress-reporter.sh "Generating property images" \
  "python3 scripts/replicate_gen.py 'image.jpg'" 90 180
```

### Interrupt a Running Job

```bash
bash scripts/progress-command.sh "stop process"
```

### Check Status Without Interrupting

```bash
bash scripts/progress-command.sh "update now"
```

## Installation

1. Copy the `job-status-control/` folder to your scripts directory
2. Make scripts executable: `chmod +x job-status-control/*.sh`
3. Configure Telegram target in scripts (line with `--target`)

## Notes

- Uses `/usr/bin/openclaw` for Telegram messaging
- Requires OpenClaw gateway with Telegram channel configured
- Status files stored in `/tmp/`
