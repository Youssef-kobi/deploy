#!/bin/bash

# Path to the .env file
ENV_PATH=".env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print section titles
print_title() {
    echo -e "${BLUE}========== $1 ==========${NC}"
}

# Function to print explanations
print_explanation() {
    echo -e "${YELLOW}$1${NC}"
}

# Function to update or add environment variables in the .env file
update_env() {
    local var_name=$1
    local var_value=$2
    # Escape special characters in var_value for sed
    local escaped_value=$(echo "$var_value" | sed -e 's/[\/&]/\\&/g')
    # Check if the variable already exists
    if grep -q "^${var_name}=" "$ENV_PATH"; then
        # Variable exists, replace it
        sed -i "s/^${var_name}=.*/${var_name}=${escaped_value}/" "$ENV_PATH"
    else
        # Variable does not exist, add it
        echo "${var_name}=${var_value}" >> "$ENV_PATH"
    fi
}

# Function to prompt for environment variable
prompt_variable() {
    local var_name=$1
    local prompt_message=$2
    local current_value=$(grep "^${var_name}=" "$ENV_PATH" | cut -d'=' -f2-)
    read -p "${prompt_message} [${current_value}]: " input_value
    input_value=${input_value:-$current_value} # Default to current value if empty
    update_env $var_name "$input_value"
}

# Ensure .env file exists or create a new one if not
if [ ! -f "$ENV_PATH" ]; then
    touch "$ENV_PATH"
    echo "Created new .env file at $ENV_PATH"
fi

print_title "Environment Setup"
print_explanation "This script will help you set up the environment variables required for deployment."

# List of required environment variables with prompts
print_title "GitHub Repository Settings"
print_explanation "Please provide the URL of your private GitHub repository and the access token for authentication."
prompt_variable "GITHUB_REPO_URL" "Enter the GitHub repository URL"
prompt_variable "GITHUB_ACCESS_TOKEN" "Enter the GitHub access token"

print_title "Server Configuration"
print_explanation "Provide the domain name for your application."
prompt_variable "SERVER_NAME" "Enter the server name (domain)"

print_title "SSL Configuration"
print_explanation "Specify the email for SSL certificate registration."
prompt_variable "EMAIL_FOR_SSL" "Enter the email for SSL certificate registration (Let's Encrypt)"

print_title "PM2 Configuration"
print_explanation "Provide the path to your PM2 ecosystem configuration file."
prompt_variable "PM2_CONFIG_PATH" "Enter the PM2 config path (default: /home/ubuntu/pm2/ecosystem.config.js)"

print_title "Logging Configuration"
print_explanation "Specify the log path for storing deployment logs."
prompt_variable "LOG_PATH" "Enter the log path (default: /var/log/deployment)"

echo -e "${GREEN}Environment setup is complete. All variables are set in the .env file.${NC}"
