#!/bin/bash

# Path to the .env file
ENV_PATH="../.env"
REPO_PATH="/var/www/html"

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

# Set NODE_ENV to production if not set
if [ -z "$NODE_ENV" ]; then
    NODE_ENV="production"
    print_message $YELLOW "NODE_ENV is not set. Defaulting to production."
fi

# Change to the repository path
cd "$REPO_PATH" || { print_message $RED "Repository path not found."; exit 1; }

# Install dependencies
print_message $YELLOW "Installing project dependencies with yarn..."
yarn install
if [ $? -eq 0 ]; then
    print_message $GREEN "Dependencies installed successfully."
else
    print_message $RED "Failed to install dependencies."
    exit 1
fi

# Build the React application
print_message $YELLOW "Building the React application with yarn..."
NODE_ENV=$NODE_ENV yarn build
if [ $? -eq 0 ]; then
    print_message $GREEN "React application built successfully."
else
    print_message $RED "Failed to build React application."
    exit 1
fi

# Ensure the build directory exists
if [ ! -d "$REPO_PATH/build" ]; then
    print_message $RED "Build directory not found. Aborting."
    exit 1
fi

# Restart Nginx to serve the built application
print_message $YELLOW "Restarting Nginx to serve the built application..."
sudo systemctl restart nginx
if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx restarted successfully."
else
    print_message $RED "Failed to restart Nginx."
    exit 1
fi

print_message $GREEN "Build and deployment of the React application completed successfully."

exit 0
