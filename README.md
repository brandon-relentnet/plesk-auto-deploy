
# Deployment Automation Script for Node.js Applications on Plesk

This script automates the setup and deployment process for Node.js applications hosted on Plesk. It generates a deployment script, links a GitHub repository, and provides Apache configuration instructions for easy integration.

## Features

- **Deployment Script**: Automatically creates a `deploy.sh` script in the domain's document root.
- **GitHub Integration**: Links a GitHub repository for automated deployment using Plesk's Git extension.
- **Apache Configuration**: Outputs a `<Location />` block for seamless Apache integration.
- **PM2 Management**: Manages application processes with PM2, ensuring reliable deployments.

---

## Prerequisites

Before running this script, ensure the following:

1. **Root SSH Terminal**: The script must be run from the **root SSH terminal**. Ensure you are logged in as `root`.

2. **Global PM2 Installation**: PM2 must be installed globally on your server. Run the following command to install PM2:
   ```bash
   npm install -g pm2
   ```

3. **SSH Access**: The domain must have SSH access set to `/bin/bash`.
   - Navigate to your domain's **Hosting & DNS** -> **Hosting** -> **SSH access** -> Set type to `/bin/bash`.

4. **Node.js Enabled**: Node.js must be enabled for the domain.
   - Go to your domain's **Dashboard** -> **Node.js** -> **Enable Node.js**.
   - Ensure that the **Document Root** and **Application Root** are correct.

---

## How to Use

### Step 1: Run the Script

Execute the script from the **root SSH terminal**:

```bash
./deploy.sh
```

### Step 2: Follow the Prompts

You will be asked to provide the following information:
- **SSH Access**: Confirm whether SSH access is set to `/bin/bash`.
- **Node.js Enabled**: Confirm whether Node.js is enabled for the domain.
- **Domain Name**: Enter the domain (e.g., `fleetingfascinations.com`).
- **Port**: Specify the port your application will use (e.g., `3000`).
- **Document Root**: Provide the document root for the domain (default: `httpdocs`).
- **GitHub Repository**: Optionally provide the SSH link to a GitHub repository for deployment, or enter `no` to skip.

### Step 3: Apache Configuration

At the end of the setup, you will receive Apache configuration instructions. If you are using Apache, follow these steps:

1. Go to your domain's **Hosting & DNS** tab -> **Apache & Nginx**.
2. Under **Additional directives for HTTPS**, copy and paste the lines provided, which look like this:

   ```apache
   <Location />
       ProxyPass http://127.0.0.1:<PORT>/
       ProxyPassReverse http://127.0.0.1:<PORT>/
   </Location>
   ```

   Replace `<PORT>` with the port you specified during the setup.

3. Click **Apply** to save the configuration.

---

## Managing PM2 Processes

To view all currently running PM2 processes across all users, use the following helper script:

```bash
./check-pm2.sh
```

This ensures visibility into all active PM2 processes on the server.

---

## Example Walkthrough

### Running the Script

1. Run the script:
   ```bash
   ./deploy.sh
   ```

2. Respond to the prompts:
   ```
   Have you already set SSH access to '/bin/bash'? (y/n): y
   Have you enabled Node.js for this domain? (y/n): y
   Enter domain (e.g., fleetingfascinations.com): fleetingfascinations.com
   Enter port (e.g., 3000): 3000
   Enter document root (default: httpdocs): httpdocs
   Add a GitHub repo (SSH link / no): git@github.com:username/repo.git
   ```

3. Output:
   - Deploy script created successfully at `/data/www/vhosts/fleetingfascinations.com/httpdocs/deploy.sh`.
   - GitHub repository successfully linked to `fleetingfascinations.com`.

4. Apache configuration provided:
   ```apache
   <Location />
       ProxyPass http://127.0.0.1:3000/
       ProxyPassReverse http://127.0.0.1:3000/
   </Location>
   ```

---

## Script Outputs

1. **Deploy Script**: Located in the document root, named `deploy.sh`.
   - Automates dependency cleanup, installation, building, and restarting the application with PM2.

2. **GitHub Integration**: Links the provided repository for automatic deployment upon push.

3. **Apache Configuration**: Provides `<Location />` block for reverse proxy setup.

---

## Notes

- The script must be run as `root`.
- Ensure PM2 is installed globally before running the script.
- For additional PM2 management, consult the [PM2 Documentation](https://pm2.keymetrics.io/).

---

## Contributing

Contributions are welcome! If you encounter issues or have suggestions, please open an issue or submit a pull request.

---

## License

This script is open-source and distributed under the MPL 2.0 License. See `LICENSE` for details.
