#!/bin/bash

# Path to the .env file
ENV_PATH=".env"
NGINX_CONF_PATH="/etc/nginx/sites-available"
NGINX_ENABLED_PATH="/etc/nginx/sites-enabled"

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

# Function to check if certbot is installed
is_certbot_installed() {
    if ! command -v certbot &> /dev/null; then
        return 1
    else
        return 0
    fi
}

# Install certbot if not installed
if ! is_certbot_installed; then
    print_message $YELLOW "Certbot is not installed. Installing certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
    if [ $? -eq 0 ]; then
        print_message $GREEN "Certbot installed successfully."
    else
        print_message $RED "Failed to install certbot."
        exit 1
    fi
else
    print_message $GREEN "Certbot is already installed."
fi

# Function to obtain and install SSL certificate
obtain_ssl_certificate() {
    print_message $YELLOW "Obtaining SSL certificate for $SERVER_NAME..."
    sudo certbot --nginx -d "$SERVER_NAME" --non-interactive --agree-tos --email "$EMAIL_FOR_SSL"
    if [ $? -eq 0 ]; then
        print_message $GREEN "SSL certificate obtained and configured successfully."
    else
        print_message $RED "Failed to obtain SSL certificate."
        exit 1
    fi
}

# Check if SSL certificate is already configured
if sudo certbot certificates | grep -q "$SERVER_NAME"; then
    print_message $GREEN "SSL certificate for $SERVER_NAME is already configured."
else
    obtain_ssl_certificate
fi

# Function to setup cron job for automatic renewal
setup_renewal_cron() {
    print_message $YELLOW "Setting up cron job for automatic SSL certificate renewal..."
    cron_job="0 0,12 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'"
    (sudo crontab -l 2>/dev/null; echo "$cron_job") | sudo crontab -
    if [ $? -eq 0 ]; then
        print_message $GREEN "Cron job for automatic SSL certificate renewal set up successfully."
    else
        print_message $RED "Failed to set up cron job for SSL certificate renewal."
        exit 1
    fi
}

# Set up the cron job if not already set
if sudo crontab -l | grep -q 'certbot renew'; then
    print_message $GREEN "Cron job for SSL certificate renewal already set up."
else
    setup_renewal_cron
fi

print_message $GREEN "SSL setup for $SERVER_NAME completed successfully."

exit 0
