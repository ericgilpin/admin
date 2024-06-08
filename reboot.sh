#!/bin/bash

# Define groups of hostnames, one per line
group1=(
    "host1"
    "host2"
    "host3"
)
group2=(
    "host4"
    "host5"
    "host6"
)
group3=(
    "host7"
    "host8"
    "host9"
)
group4=(
    "host10"
    "host11"
    "host12"
)
group5=(
    "host13"
    "host14"
    "host15"
)

# Check if group is passed as a parameter
if [ -z "$1" ]; then
    echo "Usage: $0 <group_number>"
    exit 1
fi

# Assign the correct group based on the input parameter
case "$1" in
    1) hosts=("${group1[@]}") ;;
    2) hosts=("${group2[@]}") ;;
    3) hosts=("${group3[@]}") ;;
    4) hosts=("${group4[@]}") ;;
    5) hosts=("${group5[@]}") ;;
    *) echo "Invalid group number"; exit 1 ;;
esac

# Prompt for username and password
read -p "Enter username: " username
read -s -p "Enter password: " password
echo

# Function to run ssh command with password
run_ssh() {
    sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$1" "$2"
}

# Function to check if host is available on port 22
check_host() {
    nc -z -w5 "$1" 22
}

# Reboot each host in the group
for host in "${hosts[@]}"; do
    echo "Checking $host..."
    if check_host "$host"; then
        echo "Rebooting $host..."
        run_ssh "$host" "echo '$password' | sudo -S reboot now"
        # Wait for the machine to terminate the session
        while run_ssh "$host" "exit" &>/dev/null; do
            sleep 1
        done
        echo "$host is rebooting..."
    else
        echo "Host $host is not available on port 22. Skipping."
    fi
done

# Wait for 5 minutes
echo "Waiting for 5 minutes..."
sleep 300

# Check uptime for each host
declare -A results
for host in "${hosts[@]}"; do
    echo "Checking $host uptime..."
    if check_host "$host"; then
        uptime_output=$(run_ssh "$host" "uptime -p")
        if [[ "$uptime_output" =~ "up [0-4] minute" ]]; then
            results["$host"]="Successfully rebooted"
        else
            results["$host"]="Failed to reboot"
        fi
    else
        results["$host"]="Host not reachable"
    fi
done

# Display results
echo "Reboot results:"
for host in "${!results[@]}"; do
    echo "$host: ${results[$host]}"
done
