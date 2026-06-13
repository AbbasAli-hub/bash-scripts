#!/bin/bash

log_message() {
    current_date=$(date '+%Y-%m-%d-%T')
    log_level="$1"
    message="$2"

    echo "$message"
    echo "[$current_date] $log_level: $message" >> backup.log
}

validate_path() {
    if [[ ! -d "$1" ]]; then
        log_message "ERROR" "$1 path does not exist"
        exit 1
    fi
}

transfer_backup() {
    if ! rsync -av "$1" "$2"/; then
        log_message "ERROR" "rsync failed to transfer data"
        rm -f "$backup_file"
        exit 1
    fi
}

current_date=$(date '+%Y-%m-%d-%T')

read -p "Enter source path: " source_path
validate_path "$source_path"

read -p "Do you want to store the backup on a server? (yes/y): " remote_backup_choice
read -p "Enter destination path: " destination_path

backup_file="backup_${current_date}.tar.gz"

file_count=$(find "$source_path" | wc -l)

echo "$file_count files and directories found"

if ! tar -czf "$backup_file" -C "$source_path" .; then
    log_message "ERROR" "tar failed to compress data"
    exit 1
fi

log_message "INFO" ".tar.gz archive created successfully"

if [[ "$remote_backup_choice" == "yes" || "$remote_backup_choice" == "y" ]]
then
    read -p "Enter configured server name: " server_name

    if ssh "$server_name" "ls \"$destination_path\"" > /dev/null 2>&1; then
        echo "Backup initialized..."
        transfer_backup "$backup_file" "$server_name:$destination_path"
    else
        log_message "ERROR" "Path may not exist or there may be an SSH issue"
        rm -f "$backup_file"
        exit 1
    fi

else
    validate_path "$destination_path"

    echo "Backup initialized..."
    transfer_backup "$backup_file" "$destination_path"
fi

rm -f "$backup_file"

log_message "INFO" "Backup completed successfully"
