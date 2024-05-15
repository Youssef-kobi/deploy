#!/bin/bash

# Define paths
BASE_DIR="$(dirname "$0")"
SCRIPTS_DIR="$BASE_DIR/scripts"
ENV_FILE="$BASE_DIR/.env"
ENV_SCRIPT="$SCRIPTS_DIR/setup_env.sh"
DEP_SCRIPT="$SCRIPTS_DIR/install_dependencies.sh"
GITHUB_SCRIPT="$SCRIPTS_DIR/github_ops.sh"
NGINX_SCRIPT="$SCRIPTS_DIR/configure_nginx.sh"
SSL_SCRIPT="$SCRIPTS_DIR/setup_ssl.sh"
BUILD_SCRIPT="$SCRIPTS_DIR/build_app.sh"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    local NC='\033[0m' # No Color
    echo -e "${color}${message}${NC}"
}

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'

print_message $BLUE "Starting Deployment Process..."



# Verify if scripts are executable
print_message $YELLOW "Verifying scripts in the scripts directory..."
all_executable=true
for script in "$SCRIPTS_DIR"/*.sh; do
    if [ ! -x "$script" ]; then
        all_executable=false
        break
    fi
done

if $all_executable; then
    print_message $GREEN "All scripts are already executable."
else
    print_message $YELLOW "Making scripts executable..."
    chmod +x "$SCRIPTS_DIR/"*.sh
    if [ $? -eq 0 ]; then
        print_message $GREEN "Scripts are now executable."
    else
        print_message $RED "Failed to make scripts executable."
        exit 1
    fi
fi

# Run the dependencies installation script
print_message $YELLOW "Checking and installing necessary dependencies..."
"$DEP_SCRIPT"
if [ $? -eq 0 ]; then
    print_message $GREEN "Dependencies are installed successfully."
else
    print_message $RED "Failed to install dependencies."
    exit 1
fi

# Function to check environment variables
check_env_variables() {
    local missing_vars=()
    local required_vars=("GITHUB_REPO_URL" "GITHUB_ACCESS_TOKEN" "SERVER_NAME" "EMAIL_FOR_SSL" "PM2_CONFIG_PATH" "LOG_PATH")

    for var in "${required_vars[@]}"; do
        value=$(grep "^${var}=" "$ENV_FILE" | cut -d'=' -f2-)
        if [ -z "$value" ]; then
            missing_vars+=($var)
        fi
    done

    echo "${missing_vars[@]}"
}

# Prompt to rerun the environment setup script
print_message $YELLOW "Checking if environment setup script should be rerun..."
read -p "Do you want to rerun the environment setup script to add or update values? (y/n): " rerun_env

if [ "$rerun_env" == "y" ]; then
    print_message $YELLOW "Running environment setup script..."
    "$ENV_SCRIPT"
    if [ $? -eq 0 ]; then
        print_message $GREEN "Environment setup completed successfully."
    else
        print_message $RED "Environment setup failed."
        exit 1
    fi
else
    # Check if .env file exists and if required variables have values
    if [ -f "$ENV_FILE" ]; then
        print_message $YELLOW "Verifying environment variables in .env file..."
        missing_vars=$(check_env_variables)
        
        if [ -z "$missing_vars" ]; then
            print_message $GREEN ".env file is complete with all required variables."
        else
            print_message $RED "The following environment variables are missing or empty: ${missing_vars}"
            print_message $YELLOW "Running environment setup script to complete missing values..."
            "$ENV_SCRIPT"
            if [ $? -eq 0 ]; then
                print_message $GREEN "Environment setup completed successfully."
            else
                print_message $RED "Environment setup failed."
                exit 1
            fi
        fi
    else
        print_message $RED ".env file not found."
        print_message $YELLOW "Running environment setup script..."
        "$ENV_SCRIPT"
        if [ $? -eq 0 ]; then
            print_message $GREEN "Environment setup completed successfully."
        else
            print_message $RED "Environment setup failed."
            exit 1
        fi
    fi
fi

print_message $GREEN "Initial part of deployment completed successfully. Ready for further steps."

# Run the GitHub operations script
print_message $YELLOW "Running GitHub operations script..."
"$GITHUB_SCRIPT"
if [ $? -eq 0 ]; then
    print_message $GREEN "GitHub operations completed successfully."
else
    print_message $RED "GitHub operations failed."
    exit 1
fi

# Run the Nginx configuration script
print_message $YELLOW "Running Nginx configuration script..."
"$NGINX_SCRIPT"
if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx configuration completed successfully."
else
    print_message $RED "Nginx configuration failed."
    exit 1
fi

#Run the SSL setup script
print_message $YELLOW "Running SSL setup script..."
"$SSL_SCRIPT"
if [ $? -eq 0 ]; then
    print_message $GREEN "SSL setup completed successfully."
else
    print_message $RED "SSL setup failed."
    exit 1
fi

# # Run the build application script
# print_message $YELLOW "Running build application script..."
# "$BUILD_SCRIPT"
# if [ $? -eq 0 ]; then
#     print_message $GREEN "Application build completed successfully."
# else
#     print_message $RED "Application build failed."
#     exit 1
# fi

print_message $GREEN "Deployment completed successfully."

exit 0