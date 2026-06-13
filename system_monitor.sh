#!/bin/bash

#check if mpstat command exist. if not then install it
if ! which mpstat > /dev/null; then
	echo "mpstat does not exist"
fi
logging_message() {
	current_date=$(date '+%Y-%m-%d-%T')
        log_level="$1"
        message="$2"
	if [[ "$log_level" == "ERROR" ]]; then
		echo -e '\033[0;31m' ${message} '\033[0m'
	elif [[ "$log_level" == "CAUTION" ]]; then
		echo -e '\033[1;33m' "$message" '\033[0m'
	else
		echo -e '\033[0;32m' ${message} '\033[0m'
	fi
        echo "[$current_date] $log_level: $message" >> sys_health.log
	
}

cpu_usage() {
        output=$(mpstat | awk '{print $NF}' | tail -n 1|cut -d "." -f1)
        usage=$((100-output))
        if [[ "$usage" -gt 90 ]]; then
                logging_message "ERROR" "CPU usage is above 90%"
        elif [[ "$usage" -gt 60 ]]; then
                logging_message "CAUTION" "CPU usage is above 60%"
        else
                logging_message "INFO" "CPU usage is normal"
        fi 
        echo "CPU: $usage"
}
memory_usage() {
        total=$(free -m | awk '{print $2}' | tail -n2 |head -n1)
        used=$(free -m | awk '{print $3}' | tail -n2 |head -n1)
        available=$((total-used))

        memory_in_percent=$((used*100/total))

        if [[ "$memory_in_percent" -gt 90 ]]; then
                logging_message "ERROR" "Memory usage is above 90%"
        elif [[ "$memory_in_percent" -gt 60 ]]; then
                logging_message "CAUTION" "Memory usage is above 60%"
        else
                logging_message "INFO" "Memory usage is normal"
        fi
        echo "Total: $total  Used: $used  Available: $available"
}
 
disk_usage() {
        size=$(df -m / | awk '{print $2}' | tail -n1)
        used=$(df -m / | awk '{print $3}' | tail -n1)
        available=$(df -m / | awk '{print $4}' | tail -n1)
        used_perc=$(df -m / | awk '{print $5}' | tail -n1 |sed 's/%//' )

        if [[ "$used_perc" -gt 80 ]]; then
                logging_message "ERROR" "Disk usage is above 90%"
        elif [[ "$used_perc" -gt 60 ]]; then
                logging_message "CAUTION" "Disk usage is above 60%"
        else
                logging_message "INFO" "Disk usage is normal"
        fi
        echo "Disk Size: $size  Disk Used: $used  Disk Available: $available"
}

failed_services() {
        lines=$(systemctl --failed | wc -l )
        
	if [[ "$lines" -le 3 ]]; then
		logging_message "Info" "No failed services"
		return 
	fi

	services=$(systemctl --failed | awk '{print $1}'| sed -n '2,$p'| sed '/^$/d')
        for i in $services
        do 
                echo "ERROR: $i is failed"
		logging_message "ERROR" "$i is failed" 
        done
        

}
system_uptime() {
        since=$(uptime -s)
        logging_message "Info" "System started at $since"
}

start_monitoring() {

	echo "----Uptime----"
	system_uptime
	echo 

	echo "----CPU----"
	cpu_usage
	echo 

	echo "----Memory----"
	memory_usage
	echo 

	echo "----Disk----"
	disk_usage
	echo 

	echo "----Failed services----"
	failed_services
	echo
}

#Run script in every 10 minutes
while true
do
	start_monitoring
	sleep 600
done


