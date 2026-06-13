#!/usr/bin/env 	bash

log_message() {
    local current_date=$(date '+%Y-%m-%d-%T')
    local log_level="$1"
    local message="$2"

    echo "$message"
    echo "[$current_date] $log_level: $message" >> user_management.log
}

main_menu() {
        echo "<< Select an option below >>"
        echo "1: Create a user with a home directory"
        echo "2: List all users with their groups"
        echo "3: Delete a user and their files"
        echo "4: Lock/Unlock a user account"
	echo "5: Add user to a group"
	echo "6: Exit" 
	user_input
}

validate_username() {
        local username="$1"
	if [[ "$username" == "root" ]]; then
                log_message "Error" "Cannot modify root user"
                return 1
	fi

        if [[ -z "$username" ]]; then
                log_message "Error" "Username cannot be empty"
                return 2
	elif grep -q "^$username:" /etc/passwd; then
	        return 3
      	else
 		return 4
	fi		
}
validate_group() {
	local group="$1"
	if [[ -z "$group" ]]; then
		log_message "Error" "Group name cannot be empty"
		return 1
	elif grep -q "^$group:" /etc/group; then
		return 2
	else
		return 3
	fi
}

user_input() {
        read -p "Enter the action number you want to perform: " input

        if [[ "$input" -eq 1 ]]; then
                read -p "Enter username: " username
		validate_username "$username"
		local output="$?"
		if [[ "$output" -eq 3 ]]; then
			log_message "Error" "User $username already exist"
			exit 1
		fi
                user_add "$username"
		
        elif [[ "$input" -eq 2 ]]; then
                list_user		

        elif [[ "$input" -eq 3 ]]; then
                read -p "Enter username you want to delete: " username
		validate_username "$username"
		local output="$?"

		if [[ "$output" -eq 4 ]]; then
                        log_message "Error" "User $username does not exist"
                        exit 1
		fi
                delete_user "$username"

        elif [[ "$input" -eq 4 ]]; then
                read -p "Enter username: " username
		validate_username "$username"
		local output="$?"

		if [[ "$output" -eq 4 ]]; then
                        log_message "Error" "User $username does not exist"
                        exit 1
		fi
                read -p "Choose an action [lock/unlock]: " choice

                if [[ "$choice" == "lock" ]]; then
                        lock_user "$username"

                elif [[ "$choice" == "unlock" ]]; then
                        unlock_user "$username"

                else
                        log_message "Error" "Please choose either 'lock' or 'unlock'"
                        exit 1
                fi

	elif [[ "$input" -eq 5 ]]; then
		read -p "Enter username: " username
		read -p "Enter group name: " group
		validate_username "$username"
		local output="$?"

		if [[ "$output" -eq 4 ]]; then
			log_message "Error" "User $username does not exist"
			exit 1
		fi
		validate_group "$group"
		local output2="$?"
		if [[ "$output2" -eq 3 ]]; then
                        log_message "Error" "Group $group does not exist"
                        exit 1
                fi
		add_in_group "$username" "$group"
	elif [[ "$input" -eq 6 ]]; then 
		exit 0
        else
                log_message "Error" "Invalid option. Please select a number from the menu"
                exit 1
        fi
}

user_add() {
        local username="$1"

        if ! sudo useradd -m "$username"; then
                log_message "Error" "Failed to create user '$username'"
                exit 1
        fi

        log_message "Info" "User '$username' created successfully"
}


list_user() {
        local user_groups=$(awk -F: '$3 >= 1000 {print $1}' /etc/passwd | xargs -n1 groups)

        echo "Users and their groups:"
        echo "$user_groups"
}


delete_user() {
        local username="$1"

        read -p "Are you sure you want to delete '$username'? [yes/y]: " caution

        if [[ "$caution" != "yes" && "$caution" != "y" ]]; then
                log_message "Abort" "Operation cancelled"
                exit 1
        fi


        if ! sudo userdel -r -f "$username" > /dev/null 2>&1; then
                log_message "Error" "User '$username' was not found"
                exit 1
        fi

        log_message "Info" "User '$username' deleted successfully"
}


lock_user() {
        local username="$1"

        if ! sudo usermod -L "$username"; then
                log_message "Error" "User '$username' was not found"
                exit 1
        fi

        log_message "Info" "User '$username' has been locked"
}


unlock_user() {
        local username="$1"

        if ! sudo usermod -U "$username"; then
                log_message "Error" "Cannot unlock '$username'. Set a password first or check if the user exists"
                exit 1
        fi

        log_message "Info" "User '$username' has been unlocked"
}

add_in_group() {
	local username="$1"
	local group_name="$2"

	if ! sudo usermod -aG "$group_name" "$username"; then
		log_message "Error" "Failed to add $username to $group_name"
		exit 1
	fi 
	log_message "Info" "$username added to $group_name successfully"
}	

while true; do 
	main_menu
done

