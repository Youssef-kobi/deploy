#!/bin/bash

# Define the base directory for deployment
BASE_DIR="./deploy"

# Create the main directory and subdirectories
mkdir -p "$BASE_DIR/scripts"
mkdir -p "$BASE_DIR/pm2"
mkdir -p "$BASE_DIR/logs"

# Create empty script files with shebang and make them executable
echo "#!/bin/bash" > "$BASE_DIR/deploy.sh"
echo "#!/bin/bash" > "$BASE_DIR/scripts/setup_env.sh"
echo "#!/bin/bash" > "$BASE_DIR/scripts/github_ops.sh"
echo "#!/bin/bash" > "$BASE_DIR/scripts/build_app.sh"
echo "#!/bin/bash" > "$BASE_DIR/scripts/configure_nginx.sh"
echo "#!/bin/bash" > "$BASE_DIR/scripts/setup_ssl.sh"

# Make all scripts executable
chmod +x "$BASE_DIR/deploy.sh"
chmod +x "$BASE_DIR/scripts/"*.sh

# Create a sample .env file
cat << EOF > "$BASE_DIR/.env"
# Environment Variables
GITHUB_REPO_URL=
GITHUB_ACCESS_TOKEN=
DEPLOYMENT_PATH=/var/www/myapp
NODE_ENV=production
SERVER_NAME=mydomain.com
NGINX_SITES_AVAILABLE_PATH=/etc/nginx/sites-available
NGINX_SITES_ENABLED_PATH=/etc/nginx/sites-enabled
SSL_CERT_PATH=/etc/letsencrypt/live
PM2_CONFIG_PATH=$BASE_DIR/pm2/ecosystem.config.js
LOG_PATH=$BASE_DIR/logs
EOF

# Create a sample PM2 ecosystem configuration file
cat << EOF > "$BASE_DIR/pm2/ecosystem.config.js"
module.exports = {
  apps : [{
    name: "myapp",
    script: "app.js",
    watch: true,
    env: {
        "PORT": 3000,
        "NODE_ENV": "development"
    },
    env_production: {
        "NODE_ENV": "production"
    }
  }]
};
EOF

echo "Deployment structure successfully created."
