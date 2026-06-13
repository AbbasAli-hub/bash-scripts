#!/usr/bin/env bash


validate_input() {
	local path="$1"

	if [[ -z "$path" ]]; then
		log_message "ERROR" "Empty input"
		echo "ERROR" "Input cannot be empty"
		exit 1
	elif [[ ! -f "$path" ]]; then
		log_message "ERROR" "$path does not exist"
		echo "ERROR" "$path does not exist"
		exit 1
	fi 
}

menu() {
	echo "1: Check hosts status"
	echo "2: Check ports status"
	echo "3: Exit"
	
	read -p "Select an option [1-2-3]: " choice
	if [[ ! "$choice" =~ ^[123]$ ]]; then
		log_message "ERROR" "Invalid input"
		echo "ERROR" "Enter numbers only"
		exit 1

	elif [[ "$choice" -eq 1 ]]; then
		read -p "Enter hosts file path: " path
		validate_input "$path"
		network_status "$path"

	elif [[ "$choice" -eq 2 ]]; then
		read -p "Enter ports file path: " path
		validate_input "$path"
		ports "$path"
	
	elif [[ "$choice" -eq 3 ]]; then
		log_message "INFO" "User interrupted"
		exit 0
	else
		log_message "ERROR" "Invalid option selected"
		echo "ERROR" "Please select an option from the menu"	
	fi
}

log_message() {
        local current_date=$(date '+%Y-%m-%d-%T')
        local log_level="$1"
        local message="$2"

        echo "[$current_date] $log_level: $message" >> network_health.log
}

network_status() {
	local hosts_file="$1"
	reachable_host=$(mktemp)
        unreachable_host=$(mktemp)
        local temp
        temp=$(mktemp)
        trap 'rm -f "$reachable_host" "$unreachable_host" "$temp"' EXIT

        while read -r host
        do
                ping -c4 -i0.01 "$host" > "$temp" 2>&1

                if [[ "$?" -eq 0 ]]; then
                        local response
                        response=$(tail -n1 "$temp"| awk -F "=" '{print $2}' | awk -F "/" '{print $2}')
			
                        echo "$host: Avg response time = $response" >> "$reachable_host"
                        log_message "INFO" "$host is available"
                else
                        echo "$host" >> "$unreachable_host"
                        log_message "ERROR" "$host is not available"
                fi

        done < "$hosts_file"

	summary "Hosts" "Reachable Hosts" "$reachable_host" "Unreachable hosts" "$unreachable_host"
}


check_port() {
        local port_no="$1"
        local host="$2"

        if nc -z "$host" "$port_no" > /dev/null 2>&1; then
                echo "Port: $port_no" >> "$open_ports"
                log_message "INFO" "Port $port_no is alive"
        else
                echo "Port: $port_no" >> "$closed_ports"
                log_message "ERROR" "Port $port_no is not alive"
        fi
}

ports() {
	local ports_file="$1"
	open_ports=$(mktemp)
        closed_ports=$(mktemp)
        trap 'rm -f "$open_ports" "$closed_ports"' EXIT

        
	while read -r entry; do
		local host=$(echo "$entry" | awk '{print $1}')
		local port_no=$(echo "$entry" |awk '{print $2}')
		check_port "$port_no" "$host"

	done < "$ports_file"

	summary "Ports" "Open Ports" "$open_ports" "Closed Ports" "$closed_ports"
}

summary() {
	local type="$1"
	local display1="$2"
	local output1="$3"
	local display2="$4"
	local output2="$5"

        echo "<< $type >>"
        echo

        echo "----$display1----"
        cat "$output1"

        echo

        echo "----$display2----"
        cat "$output2"

}

while true; do 
	menu
done
