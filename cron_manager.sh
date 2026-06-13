#!/usr/bin/env bash

log_message() {
        local current_date=$(date '+%Y-%m-%d-%T') 
        local log_level="$1" 
        local message="$2" 

        echo "$message"
        echo "[$current_date] $log_level: $message" >> cron_manager.log
}

validate_cron_fields() {
        local start="$1"
        local end="$2"
        local field_input="$3"

        if [[ -z "$field_input" ]]; then
                return 0

        elif [[ ! "$field_input" =~ ^[0-9]+$ ]]; then
                log_message "ERROR" "Invalid input"
                exit 1
        fi

        if [[ "$field_input" -lt "$start" || "$field_input" -gt "$end" ]]; then
                log_message "ERROR" "Invalid range"
                exit 1
        fi
}

validate_special_string() {
        local special_string="$1"

        for item in "${special_string_list[@]}"
        do
                if [[ "$item" == "$special_string" ]]; then
                        return 0
                fi
        done

        log_message "ERROR" "Invalid special string"
        exit 1
}


menu() {
        echo "1: Create cron job"
        echo "2: List all cron jobs"
        echo "3: Remove cron job"
        echo "4: Remove all scheduled jobs"
	echo "5: Exit"
        user_input
}

cron_options() {
        echo "1: Create using special string"
        echo "2: Create using manual setup"

        read -p "Select an option [1-2]: " choice

        if [[ ! "$choice" =~ ^[1-2]$ ]]; then
                log_message "ERROR" "Invalid input"
                exit 1

        elif [[ "$choice" -eq 1 ]]; then

                special_string_list=("@reboot" "@yearly" "@monthly" "@weekly" "@daily" "@hourly")

                echo "${special_string_list[@]}"

                read -p "Enter special string: " special_string
                read -p "Enter command you want to execute: " command

                validate_special_string "$special_string"
                use_special_string "$command" "$special_string"

        elif [[ "$choice" -eq 2 ]]; then

                echo "Note: If you don't want to change a field, leave it blank."

                read -p "Enter command you want to execute: " command
                read -p "Minute: " minute
                read -p "Hour: " hour
                read -p "Day: " day
                read -p "Month: " month
                read -p "Day of week: " week_day
		
                validate_cron_fields "0" "59" "$minute"
                validate_cron_fields "0" "23" "$hour"
                validate_cron_fields "1" "31" "$day"
                validate_cron_fields "1" "12" "$month"
                validate_cron_fields "0" "6" "$week_day"
		
		minute=${minute:-*}
                hour=${hour:-*}
                day=${day:-*}
                month=${month:-*}
                week_day=${week_day:-*}

                use_manual_setup "$minute" "$hour" "$day" "$month" "$week_day" "$command"

        else
                log_message "ERROR" "Invalid option selected"
                exit 1
        fi
}

user_input() {
        read -p "Select an option [1-2-3-4-5]: " option

        if [[ ! "$option" =~ ^[1-5]$ ]]; then
                log_message "ERROR" "Select option from the menu"
                exit 1

        elif [[ "$option" -eq 1 ]]; then
                cron_options

        elif [[ "$option" -eq 2 ]]; then
                list_job

        elif [[ "$option" -eq 3 ]]; then
                remove_job

 	elif  [[ "$option" -eq 4 ]]; then
		remove_all_jobs

 	elif [[ "$option" -eq 5 ]]; then
                log_message "INFO" "User interrupted the program"
                exit 0
        else
                log_message "ERROR" "Invalid input"
                exit 1
        fi

}
check_existence() {
	local new_job="$1"
	local scheduled_jobs="$2"

	while read -r job; do
		if [[ "$job" == "$new_job" ]]; then
			log_message "ERROR" "This job already exist"
			exit 1
		fi
	done < "$scheduled_jobs"
}

prepare_crontab() {
        local command="$1"
        local schedule_time="$2"
        local temp_file

        temp_file=$(mktemp)

        crontab -l > "$temp_file" 2>/dev/null
        local exit_code="$?"

        if [[ "$exit_code" -ne 0 ]]; then
                echo "$schedule_time $command" > "$temp_file"
        else
                check_existence "$schedule_time $command" "$temp_file"
                echo "$schedule_time $command" >> "$temp_file"
        fi

        echo "$temp_file"
}

use_special_string() {
        local command="$1"
        local special_string="$2"

        local output_file
        output_file=$(prepare_crontab "$command" "$special_string")

        crontab "$output_file"

        rm -f "$output_file"

        log_message "INFO" "Job scheduled successfully"
}

use_manual_setup() {
        local minute="$1"
        local hour="$2"
        local day="$3"
        local month="$4"
        local week_day="$5"
        local command="$6"

        local output_file
        output_file=$(prepare_crontab "$command" "$minute $hour $day $month $week_day")

        crontab "$output_file"

        rm -f "$output_file"

        log_message "INFO" "Job scheduled successfully"
}

check_jobs() {
        local jobs

        jobs=$(mktemp)
        crontab -l > "$jobs"
        local exit_code="$?"

        if [[ "$exit_code" -ne 0 ]]; then
                rm -f "$jobs"
                log_message "INFO" "No scheduled job found"
                return 1
        fi

        echo "$jobs"
}

list_job() {
        local jobs

        jobs=$(check_jobs) || exit 0

        cat "$jobs"

        trap 'rm -rf "$jobs"' EXIT
	rm -f "$jobs"
}

remove_job() {
        local jobs

        jobs=$(check_jobs) || exit 0

        local updated_jobs=$(mktemp)
        trap 'rm -f "$updated_jobs" "$jobs"' EXIT

        local lines=$(wc -l < "$jobs")

        echo "<< Scheduled Jobs >>"
        cat -n "$jobs"
        echo

        read -p "Enter number of job which you want to remove: " job_no

        if [[ ! "$job_no" =~ ^[0-9]+$ ]]; then
                log_message "ERROR" "Invalid input"
                exit 1

        elif [[ "$job_no" -gt "$lines" || "$job_no" -lt 1 ]]; then
                log_message "ERROR" "Invalid job number"
                exit 1
        fi

        read -p "Are you sure you want to delete job no $job_no [yes|no]?: " confirm

        if [[ "$confirm" != "yes" && "$confirm" != "y" ]]; then
                log_message "Abort" "Deletion interrupted by the user"
                exit 0
        fi

        sed "${job_no}d" < "$jobs" > "$updated_jobs"

        crontab "$updated_jobs"

        if [[ "$?" -ne 0 ]]; then
                log_message "ERROR" "Deletion failed"
                exit 1
        fi

        log_message "INFO" "Job no. $job_no deleted successfully"
	rm -f "$jobs"
}

remove_all_jobs() {
        local jobs

        jobs=$(check_jobs) || exit 0

        trap 'rm -f "$jobs"' EXIT

        read -p "Are you sure you want to delete all scheduled jobs [yes|no]?: " confirm

        if [[ "$confirm" != "yes" && "$confirm" != "y" ]]; then
                log_message "Abort" "Deletion interrupted by the user"
                exit 0
        fi

        crontab -r

        if [[ "$?" -ne 0 ]]; then
                log_message "ERROR" "Deletion failed"
                exit 1
        fi
        log_message "INFO" "All scheduled jobs deleted successfully"
	rm -f "$jobs"
}

while true; do
	menu
done
