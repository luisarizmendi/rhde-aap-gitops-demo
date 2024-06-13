#!/bin/bash

# Define the original and replacement lines
original_line="127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4"
replacement_line="127.0.0.1   microshift localhost localhost.localdomain localhost4 localhost4.localdomain4"

# Define the hosts file
hosts_file="/etc/hosts"

# Use sed to replace the line
sed -i "s|$original_line|$replacement_line|g" "$hosts_file"

echo "Hosts file replacement complete."

# Change hostname using hostnamectl
new_hostname="microshift"
sudo hostnamectl set-hostname $new_hostname --static
sudo hostnamectl set-hostname $new_hostname --transient

echo "Hostname changed to 'microshift'."
