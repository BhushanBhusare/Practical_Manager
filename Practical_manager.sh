#!/bin/bash
# ===============================================
# Project: Practical Management Software
# File: Practical_manager.sh (Final Multi-User System)
# Description: Main menu-driven practical management utility.
# ===============================================

# --- Initial Path Resolution (Absolute) ---
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
DATA_DIR="$SCRIPT_DIR/data"
PROFILES_DIR="$DATA_DIR/profiles"
CURRENT_USER_FILE="$DATA_DIR/current_user.txt" 
USER_FILE_TEMP="$CURRENT_USER_FILE" 

# --- Global Placeholders (Populated on successful login) ---
USER_FILE=""
USER_SALUTATION=""

# --- Utility Functions (Only aniecho provided for brevity) ---
aniecho(){
    local text="$1"; local newline="${2:-true}"
    for(( i=0;i<${#text};i++ )); do echo -n "${text:$i:1}"; sleep 0.005; done
    if [[ "$newline" == true ]]; then echo; fi
}

# --- Login & Data Handling Functions ---

# Function to load configuration variables after successful login
load_user_config() {
    local USER_CONFIG_PATH="$1"
    
    if [[ ! -r "$USER_CONFIG_PATH" ]]; then aniecho "[FATAL] Cannot read profile file: $USER_CONFIG_PATH. Check permissions."; return 1; fi

    USER_FILE="$USER_CONFIG_PATH"
    CONFIG_DATA=$(cat "$USER_CONFIG_PATH")
    
    # Load all variables
    USER_NAME=$(echo "$CONFIG_DATA" | grep "Name:" | cut -d: -f2 | xargs)
    USER_GENDER=$(echo "$CONFIG_DATA" | grep "Gender:" | cut -d: -f2 | xargs)
    USER_ROLL=$(echo "$CONFIG_DATA" | grep "RollNo:" | cut -d: -f2 | xargs)
    USER_DEPT=$(echo "$CONFIG_DATA" | grep "Department:" | cut -d: -f2 | xargs)
    USER_YEAR=$(echo "$CONFIG_DATA" | grep "Year:" | cut -d: -f2 | xargs)
    USER_BRANCH=$(echo "$CONFIG_DATA" | grep "Branch:" | cut -d: -f2 | xargs)
    USER_SUBJECT=$(echo "$CONFIG_DATA" | grep "Subject:" | cut -d: -f2 | xargs)
    LANG_EXT=$(echo "$CONFIG_DATA" | grep "Language_Ext:" | cut -d: -f2 | xargs)
    LANG_NAME=$(echo "$CONFIG_DATA" | grep "Language_Name:" | cut -d: -f2 | xargs)
    PRAC_CODE_BASE_DIR=$(echo "$CONFIG_DATA" | grep "Practicals_Code_Dir:" | cut -d: -f2 | xargs) 
    PRAC_DATA_BASE_DIR=$(echo "$CONFIG_DATA" | grep "Practicals_Data_Dir:" | cut -d: -f2 | xargs) 
    EDITOR_CMD=$(echo "$CONFIG_DATA" | grep "Editor_CMD:" | cut -d: -f2 | xargs)
    
    # Set salutation based on gender
    if [[ "$USER_GENDER" =~ ^[Mm] ]]; then USER_SALUTATION="Sir";
    elif [[ "$USER_GENDER" =~ ^[Ff] ]]; then USER_SALUTATION="Ma'am";
    else USER_SALUTATION=""; fi

    echo "$USER_CONFIG_PATH" > "$CURRENT_USER_FILE"
    
    aniecho "Successfully loaded profile: **$USER_NAME**."
    return 0
}

# CRITICAL NEW FUNCTION: Handles interactive input and calls sudo internally
create_new_user_via_settings() {
    aniecho "========================================"
    aniecho "[*] Starting NEW Profile Creation..."
    aniecho "========================================"
    
    # 1. Collect all interactive data first (as normal user)
    local username rollno department year branch subject gender 
    
    read_input() {
        local prompt="$1"; local var_name="$2"; local input
        while true; do
            aniecho "$prompt" false; read input;
            if [[ -z "$input" ]]; then aniecho "[ERROR] Input cannot be empty."; continue; fi
            
            # Check: Ensure name doesn't conflict with existing profile
            if [[ "$var_name" == "username" ]]; then
                local SAFE_FILENAME=$(echo "$input" | tr ' ' '_')
                if [[ -f "$PROFILES_DIR/$SAFE_FILENAME.txt" ]]; then aniecho "[ERROR] Profile '$input' already exists. Try again."; continue; fi
            fi
            
            aniecho "You entered: **$input**. Is this correct? (y/n): " false; read confirm
            if [[ $confirm =~ ^[yY]$ ]]; then eval $var_name='$input'; break; fi
        done
        return 0
    }

    if ! read_input "Enter User Name (Full Name): " username; then return 1; fi
    if ! read_input "Enter Roll No: " rollno; then return 1; fi
    read_input "Enter Department: " department
    read_input "Enter Academic Year: " year
    read_input "Enter Branch with Batch: " branch
    read_input "Enter Subject Name: " subject
    read_input "Enter Gender (M/F/Other): " gender
    
    local SAFE_FILENAME=$(echo "$username" | tr ' ' '_')
    local TEMP_SCRIPT_FILE="/tmp/profile_setup_$$$RANDOM.sh"
    
    # Write a temporary script that contains the sudo-requiring logic
    cat > "$TEMP_SCRIPT_FILE" << EOF
#!/bin/bash
# --- Sudo script for creating user profile ---

# Define variables using collected data
username="$username"
rollno="$rollno"
department="$department"
year="$year"
branch="$branch"
subject="$subject"
gender="$gender"
SAFE_FILENAME="$SAFE_FILENAME"
LANG_EXT=".c"
LANG_NAME="C"
EDITOR_CMD="nano"

ORIGINAL_USER=\$SUDO_USER
ORIGINAL_HOME=\$(getent passwd "\$ORIGINAL_USER" | cut -d: -f6)
PROJECT_ROOT="$SCRIPT_DIR/" 

PROFILES_DIR="\$PROJECT_ROOT$DATA_DIR/profiles"
CURRENT_USER_FILE="\$PROJECT_ROOT$DATA_DIR/current_user.txt"
USER_PROFILE_FILE="\$PROFILES_DIR/\$SAFE_FILENAME.txt"
DESKTOP_PRAC_DIR="\$ORIGINAL_HOME/Desktop/\$SAFE_FILENAME\_Practicals"
INTERNAL_DATA_PATH="\$PROJECT_ROOT$DATA_DIR"

# 1. Create directories
mkdir -p "\$PROFILES_DIR"
mkdir -p "\$DESKTOP_PRAC_DIR"

# 2. Write profile data
cat > "\$USER_PROFILE_FILE" << DATA_EOF
Name:\$username
Gender:\$gender
RollNo:\$rollno
Department:\$department
Year:\$year
Branch:\$branch
Subject:\$subject
Language_Ext:\$LANG_EXT
Language_Name:\$LANG_NAME
Practicals_Code_Dir:\$DESKTOP_PRAC_DIR
Practicals_Data_Dir:\$INTERNAL_DATA_PATH
Editor_CMD:\$EDITOR_CMD
DATA_EOF

# 3. Set current user file
echo "\$USER_PROFILE_FILE" > "\$CURRENT_USER_FILE"

# 4. Fix permissions (Crucial)
chown -R "\$ORIGINAL_USER": "\$PROJECT_ROOT"
chown -R "\$ORIGINAL_USER": "\$DESKTOP_PRAC_DIR"
chown "\$ORIGINAL_USER": "\$CURRENT_USER_FILE"
chown "\$ORIGINAL_USER": "\$USER_PROFILE_FILE"

echo "[SUCCESS] Profile files created."
EOF

    # 3. Execute the temporary script with sudo
    chmod +x "$TEMP_SCRIPT_FILE"
    sudo "$TEMP_SCRIPT_FILE"

    # 4. Cleanup and return status
    local STATUS=$?
    rm -f "$TEMP_SCRIPT_FILE"
    
    if [[ $STATUS -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}


# Function to display user selection menu and handle login/creation
func_switch_user() {
    local CHOICE

    while true; do
        echo
        aniecho "========================================"
        aniecho "       PROFILE MANAGEMENT"
        aniecho "========================================"
        
        local profiles=$(find "$PROFILES_DIR" -maxdepth 1 -type f -name "*.txt" -exec basename {} \; 2>/dev/null | sed 's/\.txt$//' | sort)
        local profile_count=$(echo "$profiles" | wc -l)
        
        aniecho "Available Profiles:"
        local i=1
        
        if [[ "$profile_count" -gt 0 ]]; then
            echo "$profiles" | while read -r profile_name; do
                aniecho " $i) $profile_name"
                i=$((i + 1))
            done
        else
            aniecho " (No profiles found)"
        fi

        aniecho " C) Create New Profile (Automatic)"
        aniecho " L) Login/Switch Profile (Enter Index)"
        aniecho " 0) Return to Main Menu"
        
        aniecho "Enter Option (C/L/0): " false
        read CHOICE

        if [[ "$CHOICE" =~ ^[0]$ ]]; then
            return 0 # Exit function
        elif [[ "$CHOICE" =~ ^[Cc]$ ]]; then
            if create_new_user_via_settings; then
                aniecho "Profile created. Please run the application again to log in with the new user."
                exit 0 # Exit application to force clean reload
            else
                aniecho "[ERROR] Profile creation failed. Please check permissions."
            fi
        elif [[ "$CHOICE" =~ ^[Ll]$ ]]; then
            aniecho "Enter Profile Index (1-$profile_count): " false
            read INDEX
            
            if [[ "$INDEX" =~ ^[0-9]+$ ]] && [ "$INDEX" -ge 1 ] && [ "$INDEX" -le "$profile_count" ]; then
                local selected_profile=$(echo "$profiles" | sed -n "${INDEX}p")
                local profile_path="$PROFILES_DIR/$selected_profile.txt"
                
                if load_user_config "$profile_path"; then
                    return 0 # Successful login, exit function
                fi
            else
                aniecho "[ERROR] Invalid index."
            fi
        else
            aniecho "[ERROR] Invalid option."
        fi
    done
}


# --- Application Initialization ---

# 1. Check if directories exist
mkdir -p "$DATA_DIR" "$PROFILES_DIR"

# 2. Check if a user is already loaded, otherwise load last user or switch
if [[ ! -f "$CURRENT_USER_FILE" ]]; then
    func_switch_user # No current user set, force user selection
else
    LAST_USED_PATH=$(cat "$CURRENT_USER_FILE" 2>/dev/null)
    if [[ -f "$LAST_USED_PATH" ]]; then
        if ! load_user_config "$LAST_USED_PATH"; then
             func_switch_user # Failed to load, force switch/create
        fi
    else
        aniecho "[WARNING] Last used profile path invalid. Forcing user selection."
        func_switch_user
    fi
fi

# --- Core Application Functions (Copied from final validated logic) ---

get_file_paths() {
    local prn="$1"
    PRAC_CODE="$PRAC_CODE_BASE_DIR/$prn$LANG_EXT" 
    PRAC_META_DIR="$PRAC_DATA_BASE_DIR/$prn"
    PRAC_HEADER="$PRAC_META_DIR/header.txt"
    PRAC_OUTPUT="$PRAC_META_DIR/output.txt"
}

check_practical_exist() {
    local prn="$1"
    get_file_paths "$prn"
    if [[ -f "$PRAC_CODE" ]]; then return 0; else return 1; fi
}

generate_header() {
    local prn="$1"; local prn_name="$2"
    get_file_paths "$prn"
    
    mkdir -p "$PRAC_META_DIR"
    
    cat > "$PRAC_HEADER" <<EOF
--- Intro File ---
Assignment No : $prn
Name of Assignment : $prn_name
Name : $USER_NAME
Roll No : $USER_ROLL
Department : $USER_DEPT
Year : $USER_YEAR
Subject : $USER_SUBJECT
------------------
EOF
}

# 1. View
func_view() {
    aniecho "Which practical you want to view (1/2/3/...) : " false
    read prn
    
    if ! check_practical_exist "$prn"; then aniecho "Practical $prn not found!"; return; fi
    get_file_paths "$prn"
    
    aniecho "Practical $prn found! Opening files in read mode, $USER_SALUTATION. Please wait ...."
    less "$PRAC_CODE" "$PRAC_HEADER" "$PRAC_OUTPUT" 2>/dev/null
    aniecho "Exited from Practical $prn view."
}

# 2. Edit
func_edit() {
    aniecho "Which practical you want to edit (1/2/3/...) : " false
    read prn
    
    if ! check_practical_exist "$prn"; then aniecho "Practical $prn not found! Use 'crt'."; return; fi
    
    get_file_paths "$prn"
    
    aniecho "Practical $prn located. Opening code file $prn$LANG_EXT with $EDITOR_CMD..."
    $EDITOR_CMD "$PRAC_CODE"
    
    aniecho "Practical $prn was edited successfully!"
    aniecho "Do you want to run it now? (y/n): " false
    read ops
    if [[ $ops =~ ^[yY]$ ]]; then func_run "$prn"; else aniecho "Got it $USER_SALUTATION!"; fi
}

# 3. Run
func_run() {
    local prn_input="${1}" 
    local prn
    if [[ -z "$prn_input" ]]; then aniecho "Which practical you want to run (1/2/3/...) : " false; read prn; else prn="$prn_input"; fi
    
    if ! check_practical_exist "$prn"; then aniecho "Practical $prn not found!"; return; fi

    get_file_paths "$prn"
    
    aniecho "File Execution starting (Language: $LANG_NAME) ...."
    
    echo "--- Terminal Output: $(date) ---" > "$PRAC_OUTPUT"
    
    local success=0; 
    
    echo "==========================================="
    echo "--- Execution Output for Practical $prn ---"
    
    if [[ "$LANG_EXT" == ".c" ]]; then
        mkdir -p "$PRAC_META_DIR"
        
        if ! gcc "$PRAC_CODE" -o "$PRAC_META_DIR/$prn" 2>&1 | tee -a "$PRAC_OUTPUT"; then
            echo "==========================================="
            aniecho "[ERROR] Compilation FAILED. Check terminal output for details."
            return
        fi

        echo "--- Program Runtime ---" | tee -a "$PRAC_OUTPUT"
        if "$PRAC_META_DIR/$prn" 2>&1 | tee -a "$PRAC_OUTPUT"; then
            success=1
        fi
        
    elif [[ "$LANG_EXT" == ".py" ]]; then
        echo "--- Program Runtime ---" | tee -a "$PRAC_OUTPUT"
        if python3 "$PRAC_CODE" 2>&1 | tee -a "$PRAC_OUTPUT"; then
            success=1
        fi
    fi
    
    echo "==========================================="

    if [[ $success -eq 1 ]]; then aniecho "[+] Practical $prn was successfully Executed! Output saved."; else aniecho "[!] Practical $prn had execution errors. Output saved."; fi
}

# 4. Create
func_crt() {
    aniecho "Enter NEW practical number (1/2/3/...) : " false
    read prn
    
    get_file_paths "$prn"
    
    if check_practical_exist "$prn"; then aniecho "Practical $prn already exists! Code file: $PRAC_CODE"; return; fi
    
    aniecho "Enter Practical Name (e.g., Bubble Sort) : " false
    read prn_name
    
    touch "$PRAC_CODE" 
    
    generate_header "$prn" "$prn_name"
    echo "Practical Output for $prn ($LANG_NAME)" > "$PRAC_OUTPUT" 

    aniecho "Practical $prn created successfully! Opening $LANG_NAME editor with $EDITOR_CMD..."
    $EDITOR_CMD "$PRAC_CODE"
    
    aniecho "Do you want to run the new practical now? (y/n): " false
    read ops
    if [[ $ops =~ ^[yY]$ ]]; then func_run "$prn"; else aniecho "Got it $USER_SALUTATION!"; fi
}

# 5. Remove
func_rem() {
    aniecho "Which practical you want to remove (1/2/3/...) : " false
    read prn
    
    get_file_paths "$prn"
    
    aniecho "I'm searching practical $prn, $USER_SALUTATION. Please wait ...."
    if ! check_practical_exist "$prn"; then aniecho "Practical $prn not found!"; return; fi
    
    aniecho "Practical Found! Will remove code file ($PRAC_CODE) and metadata ($PRAC_META_DIR)."
    aniecho "Please Confirm Removal (y/n) : " false
    read remo
    
    if [[ $remo =~ ^[yY]$ ]]; then
        rm -f "$PRAC_CODE"         
        rm -rf "$PRAC_META_DIR"
        aniecho "Practical $prn was removed Successfully!"
    else
        aniecho "Your file is secure, $USER_SALUTATION"
    fi
}

# 6. List
func_list() {
    aniecho "Listing all Practical Code Files in $PRAC_CODE_BASE_DIR:"
    
    local practicals=$(find "$PRAC_CODE_BASE_DIR" -maxdepth 1 -name "*$LANG_EXT" 2>/dev/null)
    
    if [[ -z "$practicals" ]]; then aniecho "No practicals found! Use 'crt' to add one."; return; fi
    
    echo "-------------------------------------"
    echo -e "PRN\tASSIGNMENT NAME"
    echo "-------------------------------------"
    
    echo "$practicals" | while read -r p_file; do
        p_filename=$(basename "$p_file")
        p_num=${p_filename%"$LANG_EXT"}
        
        get_file_paths "$p_num"
        p_name="N/A"
        
        if [[ -f "$PRAC_HEADER" ]]; then
            p_name=$(grep "Name of Assignment :" "$PRAC_HEADER" | cut -d: -f2 | xargs)
        fi
        echo -e "$p_num\t$p_name"
    done | sort -V
    
    echo "-------------------------------------"
}

# 7. Mail
func_mail() {
    aniecho "Which practical you want to mail (1/2/3/...) : " false
    read prn
    
    if ! check_practical_exist "$prn"; then aniecho "Practical $prn not found!"; return; fi
    get_file_paths "$prn"
    
    TEMP_FILENAME="Assignment_${prn}_Submission.txt"
    TEMP_FILE="/tmp/$TEMP_FILENAME"
    
    {
        echo "==================== ASSIGNMENT SUBMISSION ====================="
        cat "$PRAC_HEADER" 
        echo -e "\n\n==================== SOURCE CODE ($LANG_EXT) ====================="
        cat "$PRAC_CODE"
        echo -e "\n\n==================== EXECUTION OUTPUT ====================="
        cat "$PRAC_OUTPUT"
        echo "================================================================"
    } > "$TEMP_FILE"

    if [[ ! -f "$TEMP_FILE" ]]; then aniecho "[ERROR] Failed to create temporary file for emailing."; return; fi

    aniecho "Enter Recipient Email (e.g., professor@college.edu): " false
    read RECIPIENT_EMAIL
    
    if [[ -z "$RECIPIENT_EMAIL" ]]; then aniecho "[!] Recipient email cannot be empty. Aborting."; rm -f "$TEMP_FILE"; return; fi

    SUBJECT="Practical $prn Submission: $USER_NAME ($USER_ROLL)"
    
    BODY="Dear Sir/Ma'am,\n\nI am submitting the file for Practical No. $prn.\n\nAll assignment details, code, and execution output are included in the attached text file ($TEMP_FILENAME).\n\nThank you.\n\n$USER_NAME\nRoll No: $USER_ROLL"
    
    aniecho "Sending email with subject: **$SUBJECT** to **$RECIPIENT_EMAIL**..."
    
    eval "echo -e \"$BODY\" | mutt -s \"$SUBJECT\" -a \"$TEMP_FILE\" -- \"$RECIPIENT_EMAIL\""
    
    MAIL_STATUS=$?
    rm -f "$TEMP_FILE" 
    
    if [ $MAIL_STATUS -eq 0 ]; then aniecho "[+] Email sent successfully! File: $TEMP_FILENAME."; else aniecho "[ERROR] Failed to send email."; fi
}

# 8. Settings
func_settings() {
    local SETTINGS_FILE=$USER_FILE
    
    while true; do
        echo
        aniecho "--- Settings Menu (Profile for $USER_NAME) ---"
        aniecho "1) Name:    $USER_NAME (Cannot be changed)"
        aniecho "2) Gender:  $USER_GENDER"
        aniecho "3) Roll No: $USER_ROLL"
        aniecho "4) Dept:    $USER_DEPT"
        aniecho "5) Year:    $USER_YEAR"
        aniecho "6) Branch:  $USER_BRANCH"
        aniecho "7) Subject: $USER_SUBJECT"
        aniecho "8) Editor:  $EDITOR_CMD"
        aniecho "9) Switch/Add User"
        aniecho "0) Exit Settings Menu"
        
        echo
        aniecho "Enter index (0-9) to update: " false
        read setting_index
        
        local FIELD_KEY=""
        local CURRENT_VAL=""

        case $setting_index in
            0) aniecho "Exiting settings menu."; break ;;
            1) aniecho "[!] Name cannot be changed. It was finalized during initial setup."; continue ;;
            2) FIELD_KEY="Gender"; CURRENT_VAL="$USER_GENDER";;
            3) FIELD_KEY="RollNo"; CURRENT_VAL="$USER_ROLL";;
            4) FIELD_KEY="Department"; CURRENT_VAL="$USER_DEPT";;
            5) FIELD_KEY="Year"; CURRENT_VAL="$USER_YEAR";;
            6) FIELD_KEY="Branch"; CURRENT_VAL="$USER_BRANCH";;
            7) FIELD_KEY="Subject"; CURRENT_VAL="$USER_SUBJECT";;
            8) # Editor
                local editor_choice
                while true; do
                    aniecho "Select new editor (nano/vim/notepad (gedit)): " false
                    read editor_choice
                    case "$editor_choice" in
                        nano|vim|gedit|notepad) 
                            EDITOR_CMD="${editor_choice/notepad/gedit}"
                            break ;;
                        *) aniecho "[!] Invalid choice." ;;
                    esac
                done
                sed -i "s/^Editor_CMD:.*$/Editor_CMD:${EDITOR_CMD}/g" "$SETTINGS_FILE"
                aniecho "[+] Editor updated to **$EDITOR_CMD**!"
                continue
                ;;
            9) # Switch/Add User
                if func_switch_user; then
                   # If switch/create was successful, force return to main application loop
                   return 0
                fi
                continue
                ;;
            *) aniecho "Invalid index. Please enter a number between 0 and 9."; continue ;;
        esac
        
        # General field update logic
        aniecho "Enter new value for $FIELD_KEY (Current: $CURRENT_VAL): " false
        read new_val
        
        if [[ -n "$new_val" ]]; then
            sed -i "s/^${FIELD_KEY}:.*$/${FIELD_KEY}:${new_val}/g" "$SETTINGS_FILE"
            aniecho "[+] $FIELD_KEY updated successfully! Restart application to apply changes."
        else
            aniecho "[!] Value cannot be empty. No change made."
        fi
    done
}


# --- Main Application Loop ---

# 1. Initialization (Run only once at start)
# The application entry point logic is now condensed into a single block.
if [[ ! -f "$CURRENT_USER_FILE" ]]; then
    func_switch_user
else
    LAST_USED_PATH=$(cat "$CURRENT_USER_FILE" 2>/dev/null)
    if [[ -f "$LAST_USED_PATH" ]]; then
        if ! load_user_config "$LAST_USED_PATH"; then
             func_switch_user
        fi
    else
        aniecho "[WARNING] Last used profile path invalid. Forcing user selection."
        func_switch_user
    fi
fi


# 2. Main Menu Display
echo ""
aniecho "💻 **PRACTICAL MANAGEMENT SOFTWARE (Practical_manager.sh)**"
aniecho "Welcome, $USER_NAME! Your current language is **$LANG_NAME** ($LANG_EXT)."
aniecho "Code files are saved at: **$PRAC_CODE_BASE_DIR**"
echo -e "\n"
aniecho "       MENU
1) view : View Practical files
2) edit : Edit Practical Source Code
3) run : Run the Practical and save output
4) crt : Add New Practical
5) rem : Remove Practical
6) list : Get list of all Practicals
7) mail : Send combined practical file (.txt) 📧
8) settings : Update profile settings and editor
0) ext : Exit from software 🚪
"

while true
do
    echo
    aniecho "What you want to do $USER_SALUTATION? (Index 0-8) : " false
    read to_do
    
    case $to_do in
        1) func_view ;;
        2) func_edit ;;
        3) func_run "" ;; 
        4) func_crt ;;
        5) func_rem ;;
        6) func_list ;;
        7) func_mail ;;
        8) func_settings ;;
        0) # Exit case
            aniecho "Confirm exit (y/n) : " false
            read ops
            if [[ $ops =~ ^[yY]$ ]]; then
                aniecho "Exiting from software ...."
                aniecho "Have a good Day $USER_SALUTATION!"
                echo ""
                exit 0
            else
                aniecho "Sure $USER_SALUTATION!"
            fi
            ;;
        *)
            aniecho "Sorry $USER_SALUTATION, I didn't understand what you want to do : $to_do"
            ;;
    esac
done
