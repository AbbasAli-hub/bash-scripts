#!/usr/bin/env bash

log_message() {
    current_date=$(date '+%Y-%m-%d-%T')
    log_level="$1"
    message="$2"

    echo "$message"
    echo "[$current_date] $log_level: $message" >> parser.log
}

user_input() {
    echo "Select what type of log you want to parse"
    echo "[ 1 = File ]"
    echo "[ 2 = Service ]"

    read -p "Select from [1 and 2]: " input

    if [[ "$input" -eq 1 ]]; then
        read -p "Enter file path: " file_name
        parse_file "$file_name"

    elif [[ "$input" -eq 2 ]]; then
        read -p "Enter service name: " service_name
        parse_service "$service_name"

    else
        log_message "ERROR" "Please select from [1 and 2]"
        exit 1
    fi
}

parse_service() {
    local service_name=$1

    if ! systemctl list-units --type=service | grep -q "$service_name"; then
        log_message "ERROR" "Service not found"
        exit 1
    fi

    local tmp_file
    tmp_file=$(mktemp)

    journalctl -u "$service_name" --since "24 hours ago" --no-pager > "$tmp_file"

    log_message "INFO" "Started parsing service logs for $service_name"

    log_parsing "$tmp_file"

    rm -f "$tmp_file"
}

parse_file() {
    local file_name=$1

    if [[ ! -f "$file_name" ]]; then
        log_message "ERROR" "File does not exist"
        exit 1
    fi

    log_message "INFO" "Started parsing file: $file_name"

    log_parsing "$file_name"
}

log_parsing() {
    local log_file=$1
    local prefix

    prefix=$(grep -i "error" "$log_file" \
        | awk -F']: ' '{print $2}' \
        | sed '/^$/d' \
        | sort)

    local error_count
    error_count=$(echo "$prefix" | grep -c .)

    local top_errors
    top_errors=$(echo "$prefix" | uniq -c | sort -rn | head -n 5)

    local warning_count
    warning_count=$(grep -i "warn" "$log_file" | wc -l)

    local info_count
    info_count=$(grep -i "info" "$log_file" | wc -l)

    log_message "INFO" "Log parsing completed"

    display_details "$error_count" "$warning_count" "$info_count"

    echo "----Top 5 frequent errors----"
    echo "$top_errors"
}

display_details() {
    local error_count=$1
    local warning_count=$2
    local info_count=$3

    local analyzed_lines=$(( error_count + warning_count + info_count ))

    echo
    echo -e '\033[0;34m'"                   --------Details--------"'\033[0m'
    echo

    echo "Total lines analyzed: $analyzed_lines"
    echo

    echo -e '\033[0;31m'"ERROR count: $error_count"'\033[0m'
    echo

    echo -e '\033[1;33m'"WARNING count: $warning_count"'\033[0m'
    echo

    echo -e '\033[0;32m'"INFO count: $info_count"'\033[0m'
    echo

    log_message "INFO" "Displayed analysis summary"
}

user_input
