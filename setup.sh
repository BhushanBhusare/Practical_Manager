#!/bin/bash
# ===============================================
# Project: Practical Management Software
# File: setup.sh (Final)
# Description: Sets executable permissions and runs core_setup.sh with sudo.
# ===============================================

# Check for sudo permissions
if [ "$(id -u)" -ne 0 ]; then
    echo "This script needs to be run with sudo for permission management and package installation."
    echo "Running: sudo bash setup.sh"
    
    # Set permissions for core scripts before executing via sudo
    chmod +x core_setup.sh Practical_manager.sh
    
    # Re-execute the current script with sudo
    exec sudo "$0" "$@"
fi

# We are now running with sudo permissions.
echo "Setting executable permissions..."
chmod +x core_setup.sh Practical_manager.sh

echo "Starting core setup and configuration..."
# Execute the core setup logic
./core_setup.sh

if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "SUCCESS: Setup completed. Files and permissions are ready."
    echo "NEXT STEP: Run the application as a normal user to log in."
    echo "--------------------------------------------------------"
    echo "Run: ./Practical_manager.sh"
else
    echo "Setup failed. Please check the logs."
fi