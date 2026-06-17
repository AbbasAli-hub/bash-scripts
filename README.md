# Bash Scripts

A collection of Bash scripts built during 45 days of hands-on Linux 
practice on AWS EC2.

## Scripts

### system_monitor.sh
Monitors CPU, memory, disk usage, and failed services.
Runs every 10 minutes automatically with color coded output.

### backup_manager.sh
Automated backup script with local and remote server support.
Uses tar and rsync for compression and transfer via SSH.

### log_parser.sh
Parses log files or service logs via journalctl.
Extracts error counts, warning counts, and top 5 frequent errors.

### user_management.sh
Menu driven user management script.
Create, delete, lock, unlock users and manage group memberships.

### disk_cleanup.sh
Finds and deletes files older than X days and larger than X MB.
Shows total size before deletion and asks for confirmation.

### network_health_checker.sh
Checks reachability of hosts from a file using ping.
Verifies port status using netcat.
Generates a summary of reachable and unreachable hosts.

### cron_manager.sh
Menu driven cron job manager.
Create jobs using special strings or manual field setup.
List, remove specific, or remove all scheduled jobs.

## Requirements

- Bash 4.0+
- Linux based system
- Some scripts require sudo privileges

## Usage

```bash
chmod +x script_name.sh
./script_name.sh
```

## Author

Abbas — Commerce graduate learning DevOps in public.
Follow the journey on LinkedIn and GitHub.
