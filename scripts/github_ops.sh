#!/bin/bash

# Path to the .env file
ENV_PATH="../.env"
REPO_PATH="/var/www/html" # Default Nginx web root directory

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Load environment variables
if [ -f "$ENV_PATH" ]; then
    source "$ENV_PATH"
else
    print_message $RED "Error: .env file not found."
    exit 1
fi

# Ensure the repository URL and access token are set
if [ -z "$GITHUB_REPO_URL" ] || [ -z "$GITHUB_ACCESS_TOKEN" ]; then
    print_message $RED "Error: GITHUB_REPO_URL and GITHUB_ACCESS_TOKEN must be set in the .env file."
    exit 1
fi

# Function to clone the repository
clone_repo() {
    print_message $YELLOW "Cloning repository from $GITHUB_REPO_URL..."
    git clone "https://$GITHUB_ACCESS_TOKEN@${GITHUB_REPO_URL#https://}" "$REPO_PATH"
    if [ $? -eq 0 ]; then
        print_message $GREEN "Repository cloned successfully."
    else
        print_message $RED "Failed to clone repository."
        exit 1
    fi
}

# Function to pull the latest changes
pull_repo() {
    print_message $YELLOW "Pulling the latest changes from the repository..."
    git -C "$REPO_PATH" pull
    if [ $? -eq 0 ]; then
        print_message $GREEN "Repository updated successfully."
    else
        print_message $RED "Failed to pull the latest changes."
        exit 1
    fi
}

# Check if the repository already exists
if [ -d "$REPO_PATH/.git" ]; then
    print_message $BLUE "Repository already exists. Pulling the latest changes..."
    pull_repo
else
    print_message $BLUE "Repository does not exist. Cloning the repository..."
    clone_repo
fi

print_message $GREEN "GitHub operations completed successfully."

exit 0
