#!/bin/bash

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -qw "$1"
}

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_message $YELLOW "Updating package lists and upgrading installed packages..."
sudo apt-get update && sudo apt-get upgrade -y

# List of required packages
required_packages=(curl git nginx software-properties-common certbot)

for package in "${required_packages[@]}"; do
    if is_installed $package; then
        print_message $GREEN "$package is already installed."
    else
        print_message $YELLOW "Installing $package..."
        sudo apt-get install -y $package
        if [ $? -eq 0 ]; then
            print_message $GREEN "$package installed successfully."
        else
            print_message $RED "Failed to install $package."
            exit 1
        fi
    fi
done

print_message $GREEN "All required dependencies are installed and up to date."
