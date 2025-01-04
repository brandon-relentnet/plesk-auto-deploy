#!/bin/bash

echo "Listing PM2 processes for all Plesk system users..."

# Fetch all domains from Plesk, suppressing debug logs
domains=$(plesk bin subscription --list 2>/dev/null | awk '{print $1}' | tail -n +2)

if [ -z "$domains" ]; then
  echo "No domains found in Plesk."
  exit 1
fi

# Iterate through each domain to get the system user
for domain in $domains; do
  # Get the system user for the domain, suppressing debug logs
  system_user=$(plesk bin subscription --info "$domain" 2>/dev/null | grep -i "FTP Login" | awk '{print $NF}')

  if [ -n "$system_user" ]; then
    # echo "Checking PM2 processes for domain: $domain (user: $system_user)"

    # Set PM2_HOME and check processes
    home_dir=$(getent passwd "$system_user" | cut -d: -f6)
    pm2_dir="$home_dir/.pm2"

    if [ -d "$pm2_dir" ]; then
      PM2_HOME="$pm2_dir" pm2 list || echo "No PM2 instances for $system_user."
      echo ""
    # else
      # echo "No PM2 directory found for user: $system_user"
    fi
  else
    echo "Could not determine the system user for domain: $domain"
  fi
done