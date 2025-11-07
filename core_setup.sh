#!/bin/bash
# ===============================================
# Project: Practical Management Software
# File: core_setup.sh (Final Multi-User Fix)
# Description: Collects user profile data, installs packages, and fixes permissions.
# ===============================================

# Global configuration paths
DATA_DIR="data"
USER_FILE="$DATA_DIR/user.txt"
PROJECT_ROOT="$(pwd)/" 

# --- Utility Functions ---
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

install_packages() {
    echo "==================================="
    aniecho "[*] Checking and Installing prerequisites..."
    echo "==================================="
    
    REQUIRED_PACKAGES="vim nano mutt mailutils curl wget gnupg2 build-essential gedit git"
    export DEBIAN_FRONTEND=noninteractive

    sudo apt update -y 
    if [ $? -ne 0 ]; then aniecho "[!] Error updating system."; return 1; fi
    
    sudo apt install -y $REQUIRED_PACKAGES
    
    unset DEBIAN_FRONTEND
    if [ $? -ne 0 ]; then aniecho "[!] Error installing packages."; return 1; fi

    aniecho "[+] All required packages installed successfully!"
    return 0
}

# --- Core User Creation Function ---
create_new_profile_logic() {
    echo "===================================="
    aniecho "[*] Creating NEW User Profile..."
    echo "===================================="
    
    ORIGINAL_USER=${SUDO_USER:-$(whoami)}
    ORIGINAL_HOME=$(getent passwd "$ORIGINAL_USER" | cut -d: -f6)

    local username rollno department year branch subject gender lang_ext lang_name editor_cmd

    read_input() {
        local prompt="$1"; local var_name="$2"; local input
        while true; do
            aniecho "$prompt" false
            read input < /dev/tty
            
            if [[ -z "$input" ]]; then aniecho "[!] Input cannot be empty. Please try again."; continue; fi

            aniecho "You entered: **$input**. Is this correct? (y/n): " false
            read confirm < /dev/tty
            if [[ $confirm =~ ^[yY]$ ]]; then
                eval $var_name='$input'
                break
            fi
        done
        return 0
    }
    
    # Input Collection (This relies on read_input which reads from /dev/tty even under sudo)
    if ! read_input "Enter User Name (Full Name): " username; then return 1; fi
    if ! read_input "Enter Roll No: " rollno; then return 1; fi
    read_input "Enter Department: " department
    read_input "Enter Academic Year (e.g., 2025-26): " year
    read_input "Enter Branch with Batch (e.g., CSD-S1): " branch
    read_input "Enter Subject Name: " subject
    read_input "Enter Gender (M/F/Other): " gender
    
    lang_ext=".c"; lang_name="C"
    editor_cmd="nano" 
    
    # --- Construct and Create Paths ---
    SAFE_FILENAME=$(echo "$username" | tr ' ' '_')
    
    DESKTOP_PRAC_DIR="$ORIGINAL_HOME/Desktop/${SAFE_FILENAME}_Practicals"
    INTERNAL_DATA_PATH="$PROJECT_ROOT$DATA_DIR"
    FINAL_USER_FILE="$PROJECT_ROOT$DATA_DIR/profiles/$SAFE_FILENAME.txt" 
    CURRENT_USER_ACTIVE_FILE="$PROJECT_ROOT$DATA_DIR/current_user.txt"
    
    # Create directories
    mkdir -p "$PROJECT_ROOT$DATA_DIR" "$PROJECT_ROOT$DATA_DIR/profiles"
    mkdir -p "$DESKTOP_PRAC_DIR"

    # --- Write Data to user.txt (Guaranteed write using tee) ---
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
    } | sudo tee "$FINAL_USER_FILE" > /dev/null

    # Set the newly created profile as the current active profile
    echo "$FINAL_USER_FILE" | sudo tee "$CURRENT_USER_ACTIVE_FILE" > /dev/null

    # --- Permission Fix (CRITICAL) ---
    sudo chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$PROJECT_ROOT"
    sudo chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$DESKTOP_PRAC_DIR"
    
    # Verify the write operation
    if [[ -f "$FINAL_USER_FILE" && -s "$FINAL_USER_FILE" ]]; then
        aniecho "[+] Setup data saved successfully."
    else
        aniecho "[FATAL] Data write failed. Setup aborted."
        return 1
    fi
    return 0
}

setup_mutt() {
    echo "==============================="
    aniecho "[*] Project Email Setup (Mutt)"
    echo "==============================="

    SENDER_EMAIL="practical.manager01@gmail.com"
    APP_PASSWORD="wlpk kmnf fshh lqnc" 
    REAL_NAME="Practical Manager"
    
    if [[ "$APP_PASSWORD" == "wlpk kmnf fshh lqnc" ]]; then
        aniecho "[!] WARNING: Please update the APP_PASSWORD in core_setup.sh for email functionality."
    fi

    ORIGINAL_USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    MUTT_RC="$ORIGINAL_USER_HOME/.muttrc"

    cat > "$MUTT_RC" <<EOF
set realname = "$REAL_NAME"
set from = "$SENDER_EMAIL"
set use_from = yes
set envelope_from = yes

set smtp_url = "smtps://$SENDER_EMAIL@smtp.gmail.com:465/"
set smtp_pass = "$APP_PASSWORD"
set ssl_force_tls = yes
set editor="nano"
set move = no
set charset="utf-8"
EOF

    sudo chown "$SUDO_USER":"$SUDO_USER" "$MUTT_RC"
    sudo chmod 600 "$MUTT_RC"

    aniecho "[+] Mutt configured successfully!"
}

# --- Main Execution ---
main() {
    if [ -z "$SUDO_USER" ]; then aniecho "[FATAL] core_setup.sh must be run via setup.sh using sudo."; exit 1; fi
    
    if ! install_packages; then exit 1; fi
    
    # If no profile exists, force creation
    if [[ ! -f "$PROJECT_ROOT$CURRENT_USER_FILE" ]] || [[ -z "$(ls -A "$PROJECT_ROOT$PROFILES_DIR" 2>/dev/null)" ]]; then
        aniecho "--- Initial Setup: Creating first profile. ---"
        if ! create_new_profile_logic; then exit 1; fi
    fi

    setup_mutt
    
    echo "========================================================="
    aniecho "Setup completed! Application ready."
    echo "========================================================="
}

main



