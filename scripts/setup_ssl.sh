#!/bin/bash

# Path to the .env file
ENV_PATH=".env"

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

# Ensure the required environment variables are set
if [ -z "$SERVER_NAME" ] || [ -z "$EMAIL_FOR_SSL" ]; then
    print_message $RED "Error: SERVER_NAME and EMAIL_FOR_SSL must be set in the .env file."
    exit 1
fi

# Check if Certbot is installed
if ! command -v certbot &> /dev/null; then
    print_message $RED "Certbot is not installed. Installing Certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
    if [ $? -eq 0 ]; then
        print_message $GREEN "Certbot installed successfully."
    else
        print_message $RED "Failed to install Certbot."
        exit 1
    fi
else
    # Check if Certbot Nginx plugin is installed
    if ! dpkg -l | grep -qw python3-certbot-nginx; then
        print_message $RED "Certbot Nginx plugin is not installed. Installing Certbot Nginx plugin..."
        sudo apt-get update
        sudo apt-get install -y python3-certbot-nginx
        if [ $? -eq 0 ]; then
            print_message $GREEN "Certbot Nginx plugin installed successfully."
        else
            print_message $RED "Failed to install Certbot Nginx plugin."
            exit 1
        fi
    else
        print_message $GREEN "Certbot and Certbot Nginx plugin are already installed."
    fi
fi

# Obtain SSL certificate using Certbot
print_message $YELLOW "Obtaining SSL certificate for $SERVER_NAME..."
sudo certbot --nginx -d "$SERVER_NAME" --non-interactive --agree-tos --email "$EMAIL_FOR_SSL"
if [ $? -eq 0 ]; then
    print_message $GREEN "SSL certificate obtained successfully."
else
    print_message $RED "Failed to obtain SSL certificate."
    exit 1
fi

# Verify if Certbot renewal cron job is set up
print_message $YELLOW "Checking for Certbot renewal cron job..."
if ! sudo crontab -l | grep -q "certbot renew"; then
    print_message $YELLOW "Setting up Certbot renewal cron job..."
    (sudo crontab -l 2>/dev/null; echo "0 0,12 * * * certbot renew --quiet --deploy-hook 'systemctl reload nginx'") | sudo crontab -
    if [ $? -eq 0 ]; then
        print_message $GREEN "Certbot renewal cron job set up successfully."
    else
        print_message $RED "Failed to set up Certbot renewal cron job."
        exit 1
    fi
else
    print_message $GREEN "Certbot renewal cron job is already set up."
fi

# Check if Nginx is running and start it if necessary
print_message $YELLOW "Checking if Nginx is running..."
if systemctl is-active --quiet nginx; then
    print_message $GREEN "Nginx is running."
else
    print_message $YELLOW "Nginx is not running. Starting Nginx..."
    sudo systemctl start nginx
    if [ $? -eq 0 ]; then
        print_message $GREEN "Nginx started successfully."
    else
        print_message $RED "Failed to start Nginx. Gathering diagnostic information..."
        sudo systemctl status nginx.service
        sudo journalctl -xe
        exit 1
    fi
fi

# Reload Nginx to apply the changes
print_message $YELLOW "Reloading Nginx to apply the SSL changes..."
sudo systemctl reload nginx
if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx reloaded successfully."
else
    print_message $RED "Failed to reload Nginx."
    exit 1
fi

print_message $GREEN "SSL setup and configuration for $SERVER_NAME completed successfully."

exit 0
