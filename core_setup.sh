#!/bin/bash
# ===============================================
# Project: Practical Management Software
# File: core_setup.sh (Final Multi-User Fix)
# Description: Collects user profile data, installs packages, and fixes permissions.
# ===============================================

# Global configuration paths (Now simple relative names)
DATA_DIR="data"
PROFILES_DIR="$DATA_DIR/profiles"
CURRENT_USER_FILE="$DATA_DIR/current_user.txt"

# CRITICAL FIX: PROJECT_ROOT is the ABSOLUTE path of the project directory.
PROJECT_ROOT="$(pwd)/" 

# --- Utility Functions (Omitted aniecho, install_packages for brevity, they are assumed to be present) ---
# ... (aniecho function)
aniecho(){
    local text="$1"
    local newline="${2:-true}"
    for(( i=0;i<${#text};i++ ))
    do
        echo -n "${text:$i:1}"
        sleep 0.005
    done
    if [[ "$newline" == true ]]; then
        echo
    fi
}
# ... (install_packages function)
install_packages() {
    echo "==================================="
    aniecho "[*] Checking and Installing prerequisites..."
    REQUIRED_PACKAGES="vim nano mutt mailutils curl wget gnupg2 build-essential gedit git"
    export DEBIAN_FRONTEND=noninteractive
    sudo apt update -y 
    sudo apt install -y $REQUIRED_PACKAGES
    unset DEBIAN_FRONTEND
    if [ $? -ne 0 ]; then aniecho "[!] Error installing packages."; return 1; fi
    aniecho "[+] All required packages installed successfully!"
    return 0
}

# --- Core User Creation Function ---
create_new_profile_logic() {
    ORIGINAL_USER=${SUDO_USER:-$(whoami)}
    ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

    local username rollno department year branch subject gender lang_ext lang_name editor_cmd

    read_input() {
        local prompt="$1"; local var_name="$2"; local input
        while true; do
            aniecho "$prompt" false
            read input < /dev/tty
            
            # Check 1: Ensure name doesn't conflict with existing profile
            if [[ "$var_name" == "username" ]]; then
                SAFE_FILENAME=$(echo "$input" | tr ' ' '_')
                if [[ -f "$PROJECT_ROOT$PROFILES_DIR/$SAFE_FILENAME.txt" ]]; then
                    aniecho "[ERROR] Profile for '$input' already exists. Aborting creation."
                    return 1
                fi
            fi

            aniecho "You entered: **$input**. Is this correct? (y/n): " false
            read confirm < /dev/tty
            if [[ $confirm =~ ^[yY]$ ]]; then
                eval $var_name='$input'
                break
            fi
        done
        return 0
    }
    
    # Input Collection (Exiting if read fails, or profile exists)
    if ! read_input "Enter User Name (Full Name): " username; then return 1; fi
    if ! read_input "Enter Roll No: " rollno; then return 1; fi
    read_input "Enter Department: " department
    read_input "Enter Academic Year (e.g., 2025-26): " year
    read_input "Enter Branch with Batch (e.g., CSD-S1): " branch
    read_input "Enter Subject Name: " subject
    read_input "Enter Gender (M/F/Other): " gender
    
    lang_ext=".c"; lang_name="C"
    editor_cmd="nano" 
    
    # --- Construct Paths ---
    SAFE_FILENAME=$(echo "$username" | tr ' ' '_')
    USER_PROFILE_FILE="$PROJECT_ROOT$PROFILES_DIR/$SAFE_FILENAME.txt"
    DESKTOP_PRAC_DIR="$ORIGINAL_HOME/Desktop/${SAFE_FILENAME}_Practicals"
    INTERNAL_DATA_PATH="$PROJECT_ROOT$DATA_DIR"

    # --- Create Directories and Write Data ---
    mkdir -p "$PROJECT_ROOT$DATA_DIR" "$PROJECT_ROOT$PROFILES_DIR"
    mkdir -p "$DESKTOP_PRAC_DIR"
    
    # Guaranteed write using tee
    {
        echo "Name:$username"
        echo "Gender:$gender"
        echo "RollNo:$rollno"
        echo "Department:$department"
        echo "Year:$year"
        echo "Branch:$branch"
        echo "Subject:$subject"
        echo "Language_Ext:$lang_ext"
        echo "Language_Name:$lang_name"
        echo "Practicals_Code_Dir:$DESKTOP_PRAC_DIR"
        echo "Practicals_Data_Dir:$INTERNAL_DATA_PATH"
        echo "Editor_CMD:$editor_cmd"
        echo "Profile_ID:$SAFE_FILENAME" # Unique identifier
    } | sudo tee "$USER_PROFILE_FILE" > /dev/null

    # Set the newly created profile as the current active profile
    echo "$USER_PROFILE_FILE" | sudo tee "$PROJECT_ROOT$CURRENT_USER_FILE" > /dev/null

    # --- Permission Fix (CRITICAL) ---
    sudo chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$PROJECT_ROOT"
    sudo chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$DESKTOP_PRAC_DIR"
    
    aniecho "[+] Profile created: $username. Setup successful."
    return 0
}

# --- Main Execution ---
main() {
    if [ -z "$SUDO_USER" ]; then aniecho "[FATAL] core_setup.sh must be run via setup.sh using sudo."; exit 1; fi
    
    # Installation (only run once)
    if ! command -v mutt &> /dev/null; then
        if ! install_packages; then exit 1; fi
    fi
    
    # Create required directory structure
    mkdir -p "$PROJECT_ROOT$PROFILES_DIR"

    # If no profile exists, force creation
    if [[ ! -f "$PROJECT_ROOT$CURRENT_USER_FILE" ]] || [[ -z "$(ls -A "$PROJECT_ROOT$PROFILES_DIR" 2>/dev/null)" ]]; then
        aniecho "--- No existing profiles found. Creating initial profile. ---"
        if ! create_new_profile_logic; then
            aniecho "[FATAL] Initial profile creation failed."
            exit 1
        fi
    fi

    # Mutt Setup (Must run once per user in their HOME dir, which is handled via chown)
    # The actual mutt config file creation is omitted here for brevity but assumes it runs.

    echo "========================================================="
    aniecho "Setup completed! Application ready."
    echo "========================================================="
}

main