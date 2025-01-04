#!/bin/bash

# Prompt for SSH access check
read -p "Have you already set SSH access to '/bin/bash'? (y/n): " SSH_ACCESS
if [ "$SSH_ACCESS" != "y" ]; then
  echo "Please set SSH access to '/bin/bash' for this domain."
  echo "Go to the domain page -> 'Hosting & DNS' tab -> 'Hosting' -> 'SSH access' -> set type to '/bin/bash'."
  exit 1
fi

# Prompt for Node.js enablement
read -p "Have you enabled Node.js for this domain? (y/n): " NODEJS_ENABLED
if [ "$NODEJS_ENABLED" != "y" ]; then
  echo "Please enable Node.js for this domain."
  echo "Go to the domain page -> 'Dashboard' tab -> 'Node.js' -> 'Enable Node.js'."
  echo "Make sure your document root and application root are correct."
  exit 1
fi

# Prompt for domain
read -p "Enter domain (e.g., fleetingfascinations.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "Error: Domain is required."
  exit 1
fi

# Prompt for port
read -p "Enter port (e.g., 3000): " PORT
if [ -z "$PORT" ]; then
  echo "Error: Port is required."
  exit 1
fi

# Prompt for document root
read -p "Enter document root (default: httpdocs): " DOC_ROOT
DOC_ROOT=${DOC_ROOT:-httpdocs}

# Determine the app directory
BASE_DIR="/data/www/vhosts"
APP_DIR="${BASE_DIR}/${DOMAIN}/${DOC_ROOT}"

# Verify the app directory exists
if [ ! -d "$APP_DIR" ]; then
  echo "Error: App directory does not exist: $APP_DIR"
  exit 1
fi

# Get the FTP user for the domain
SYSTEM_USER=$(plesk bin subscription --info "$DOMAIN" 2>/dev/null | grep -i "FTP Login" | awk '{print $NF}')
if [ -z "$SYSTEM_USER" ]; then
  echo "Error: Could not find system user for $DOMAIN."
  exit 1
fi

# Define the deploy script content
DEPLOY_SCRIPT_CONTENT=$(cat <<EOF
#!/bin/bash

# Define the app directory and port
APP_DIR="${APP_DIR}"
PORT="${PORT}"

echo "Starting deployment process for ${DOMAIN}..."

# Kill the process running on the specified port
echo "Stopping process on port \$PORT..."
fuser -k \${PORT}/tcp >/dev/null 2>&1 || echo "No process running on port \$PORT."

# Navigate to the app directory
cd \$APP_DIR || { echo "Error: App directory not found."; exit 1; }

# Clean up old dependencies
echo "Cleaning up old dependencies..."
rm -rf node_modules package-lock.json >/dev/null 2>&1 || echo "No previous dependencies to clean."

# Install dependencies
echo "Installing dependencies..."
npm install >/dev/null 2>&1 || { echo "Error: Installing dependencies failed."; exit 1; }

# Build the application
echo "Building the application..."
npm run build >/dev/null 2>&1 || { echo "Error: Build failed."; exit 1; }

# Restart the application with PM2
PM2_NAME="${DOMAIN//./_}"
echo "Starting the application with PM2 (name: \$PM2_NAME)..."
pm2 delete "\$PM2_NAME" >/dev/null 2>&1 || echo "No previous PM2 process to delete."
pm2 start npm --name "\$PM2_NAME" -- start >/dev/null 2>&1 || { echo "Error: Failed to start the application."; exit 1; }

echo "Deployment completed successfully for ${DOMAIN}."
EOF
)

# Write the deploy script to the document root
DEPLOY_SCRIPT_PATH="${APP_DIR}/deploy.sh"
echo "Creating deploy script at: ${DEPLOY_SCRIPT_PATH}"
echo "$DEPLOY_SCRIPT_CONTENT" > "$DEPLOY_SCRIPT_PATH"

# Set execute permissions on the deploy script
chmod +x "$DEPLOY_SCRIPT_PATH"

# Set ownership to the system user
chown "$SYSTEM_USER":"psacln" "$DEPLOY_SCRIPT_PATH" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Ownership set for $DEPLOY_SCRIPT_PATH to $SYSTEM_USER."
else
  echo "Error: Failed to set ownership for $DEPLOY_SCRIPT_PATH."
fi

echo "Deploy script created successfully at ${DEPLOY_SCRIPT_PATH}."

# Prompt to add a GitHub repo
read -p "Add a GitHub repo (SSH link / no): " REPO_LINK
if [ "$REPO_LINK" != "no" ] && [ -n "$REPO_LINK" ]; then
  echo "Setting up GitHub repository for ${DOMAIN}, this may take a few minutes..."

  # Add the GitHub repository using Plesk Git
  plesk ext git --create -domain "$DOMAIN" -name pull -remote-url "$REPO_LINK" -actions "bash ${DEPLOY_SCRIPT_PATH}" -deployment-mode auto >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "GitHub repository successfully linked to ${DOMAIN}."
  else
    echo "Error: Failed to set up GitHub repository."
  fi
else
  echo "No GitHub repository added."
fi

# Print Apache configuration instructions
APACHE_CONFIG=$(cat <<EOF

<Location />
    ProxyPass http://127.0.0.1:${PORT}/
    ProxyPassReverse http://127.0.0.1:${PORT}/
</Location>

EOF
)

echo "Setup complete for ${DOMAIN}."
echo ""
echo "**If you are using Apache web services, follow these steps**"
echo "1. Go to the domain page -> 'Hosting & DNS' tab -> 'Apache & Nginx'."
echo "2. Under 'Additional directives for HTTPS', copy and paste the lines below:"
echo "$APACHE_CONFIG"
echo "3. Click 'Apply'."

echo ""
echo "Each domain will have its own pm2 process. To view all the currently running processes, use the following commands:"
echo "./check-pm2.sh"