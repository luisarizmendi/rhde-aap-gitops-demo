#!/bin/bash


# Function to check the status of the `oc` command
check_oc_command() {
    oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pods --all-namespaces &> /dev/null
    return $?
}

# Loop to run the script multiple times to be sure
for ((i=1; i<=3; i++)); do

    # Loop until the `oc` command succeeds
    until check_oc_command; do
        echo "Waiting for the oc command to succeed..."
        sleep 10
    done

    all_running_completed=false

    while ! $all_running_completed; do
        all_running_completed=true
        statuses=$(oc --kubeconfig /var/lib/microshift/resources/kubeadmin/kubeconfig get pods --all-namespaces | awk '{print $4}' | grep -v -e "Ready" -e "Completed" | grep -v STATUS)

        for status in $statuses; do
            # Check if the status is not Running or Completed
            if [ "$status" != "Running" ] && [ "$status" != "Completed" ]; then
                # If any status is not Running or Completed, set the variable to false and break the loop
                all_running_completed=false
                break
            fi
        done

        if $all_running_completed; then
            break
        fi

        sleep 5
    done
done

echo "All statuses are now Running or Completed."