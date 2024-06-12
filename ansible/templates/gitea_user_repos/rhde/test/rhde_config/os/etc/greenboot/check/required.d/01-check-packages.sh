#!/bin/bash

# List of required packages
required_packages=("kiosk-mode" "git")

# Check if each package is installed
for package in "${required_packages[@]}"; do
    if ! rpm -q "$package" &>/dev/null; then
        echo "Error: $package is not installed."
        exit 1
    fi
done

echo "All required packages are installed."