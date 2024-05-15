#!/bin/bash

# Path to the .env file
ENV_PATH=".env"
DEFAULT_DEPLOYMENT_PATH="/var/www/html"

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
if [ -z "$SERVER_NAME" ]; then
    print_message $RED "Error: SERVER_NAME must be set in the .env file."
    exit 1
fi

# Paths for Nginx configuration
NGINX_CONF_FILE="/etc/nginx/sites-available/$SERVER_NAME"
NGINX_CONF_LINK="/etc/nginx/sites-enabled/$SERVER_NAME"

# Create the Nginx configuration file
print_message $YELLOW "Creating Nginx configuration for $SERVER_NAME..."

cat <<EOF | sudo tee "$NGINX_CONF_FILE" > /dev/null
server {
    listen 80;
    server_name $SERVER_NAME;

    root $DEFAULT_DEPLOYMENT_PATH/build;
    index index.html;

    location / {
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx configuration file created successfully."
else
    print_message $RED "Failed to create Nginx configuration file."
    exit 1
fi

# Enable the Nginx configuration
print_message $YELLOW "Enabling Nginx configuration for $SERVER_NAME..."
sudo ln -sf "$NGINX_CONF_FILE" "$NGINX_CONF_LINK"
if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx configuration enabled successfully."
else
    print_message $RED "Failed to enable Nginx configuration."
    exit 1
fi

# Test the Nginx configuration
print_message $YELLOW "Testing Nginx configuration..."
sudo nginx -t
if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx configuration is valid."
else
    print_message $RED "Nginx configuration is invalid. Aborting."
    exit 1
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
print_message $YELLOW "Reloading Nginx to apply the changes..."
sudo systemctl reload nginx
if [ $? -eq 0 ]; then
    print_message $GREEN "Nginx reloaded successfully."
else
    print_message $RED "Failed to reload Nginx."
    exit 1
fi

print_message $GREEN "Nginx configuration for $SERVER_NAME completed successfully."

exit 0
