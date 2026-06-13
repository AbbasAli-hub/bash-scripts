#!/usr/bin/env bash

log_message() {
    local current_date=$(date '+%Y-%m-%d-%T')
    local log_level="$1"
    local message="$2"

    echo "$message"
    echo "[$current_date] $log_level: $message" >> disk_cleanup.log
}

menu() {
    echo "1: Dry Run"
    echo "2: Delete Files"
    echo "3: Exist"

    read -p "Select an option [1-2]: " choice

    if [[ "$choice" == 1 ]]; then
        dry_run
    elif [[ "$choice" == 2 ]]; then
        delete_files
    elif [[ "$choice" == 3 ]]; then
	    exit 0
    else
        log_message "ERROR" "Invalid option selected"
    fi
}

dry_run() {
    user_input

    echo "Matching files:"
    cat "$temp_file"
    echo "Estimated space to be freed: $total_size"

    rm -f "$temp_file"
    confirm_file_deletion "$temp_file"
    exit 0
}

delete_files() {
    user_input
    echo "Matching Files:"
    cat "$temp_file"
    echo "Estimated space to be freed: $total_size"
    
    deletion
    rm -f "$temp_file"
    confirm_file_deletion "$temp_file"
}
confirm_file_deletion() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
	    log_message "ERROR" "Failed to delete $file"
	    return 1
    fi 
    return 0
}
user_input() {
    read -p "Enter the source directory path: " path

    if [[ ! -d "$path" ]]; then
        log_message "ERROR" "Directory does not exist"
        exit 1
    fi

    read -p "Enter the minimum file age in days [default: 10]: " days
    if [[ -z "$days" ]]; then
	    days=10
    elif [[ ! "$days" =~ ^[0-9]+$ ]]; then
        log_message "ERROR" "Please enter a valid numeric value"
        exit 1
    fi

    read -p "Enter the minimum file size in MB [default: 20MB]: " size
    if [[ -z "$size" ]]; then
	    size=20
    
    elif [[ ! "$size" =~ ^[0-9]+$ ]]; then
        log_message "ERROR" "Please enter a valid numeric value"
        exit 1
    fi

    find_files "$path" "$days" "$size"
}

find_files() {
    local path="$1"
    local days="$2"
    local size="$3"

    temp_file=$(mktemp)

    find "$path" -type f -size +"${size}M" -mtime +"$days" > "$temp_file"

    if [[ ! -s "$temp_file" ]]; then
        echo "No files matched the specified criteria"
        rm -f "$temp_file"
	confirm_file_deletion "$temp_file"
        exit 0
    fi

    total_size=$(xargs du -ch < "$temp_file" | tail -n 1 | awk '{print $1}')
}

deletion() {
    read -p "Do you want to delete the listed files? [yes/no]: " choice

    if [[ "$choice" != "yes" && "$choice" != "y" ]]; then
        rm -f "$temp_file"
	confirm_file_deletion "$temp_file"
        log_message "INFO" "File deletion cancelled by user"
        exit 0
    fi

    while read -r file
    do
        rm -f "$file"
        if confirm_file_deletion "$file"; then
		log_message "INFO" "Deleted: $file"
	fi
    done < "$temp_file"

    local file_count
    file_count=$(wc -l < "$temp_file")

    echo "Files deleted successfully: $file_count"
    echo "Space freed: $total_size"
}

while true
do
    menu
done
