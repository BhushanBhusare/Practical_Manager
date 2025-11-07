#!/bin/bash
# ===============================================
# Project: Practical Management Software Launcher
# File: launch.sh (FIXED: Terminal Stay-Open)
# Description: Launches Practical_manager.sh in a dedicated, maximized terminal window.
# ===============================================

# --- Define the Main Script Path ---
MAIN_SCRIPT="$(dirname "$(readlink -f "$0")")/Practical_manager.sh"

# --- Check for Terminal Type ---

if command -v gnome-terminal &> /dev/null; then
    
    # GNOME-TERMINAL Launch Method (Maximized, with Title)
    # FIX: We use a final 'read' command to keep the terminal open after the main script exits.
    gnome-terminal \
        --title="PRACTICAL MANAGER" \
        --geometry=180x50 \
        --maximize \
        -- /bin/bash -c "chmod +x '$MAIN_SCRIPT'; '$MAIN_SCRIPT'; echo '---------------------------------------'; echo 'Application finished. Press Enter to close this window...'; read" &

elif command -v xterm &> /dev/null; then
    
    # XTERM Launch Method 
    # FIX: Using '-hold' to keep the window open after execution (if supported) or adding 'read' command.
    xterm \
        -T "PRACTICAL MANAGER" \
        -fullscreen \
        -e "chmod +x '$MAIN_SCRIPT'; '$MAIN_SCRIPT'; echo 'Press Enter to close...'; read" &

else
    echo "[FATAL] Neither 'gnome-terminal' nor 'xterm' found."
    echo "Cannot launch the application in a separate window."
    echo "--- Running in current terminal ---"
    
    # Run the script in the current window as a fallback
    chmod +x "$MAIN_SCRIPT"
    "$MAIN_SCRIPT"
fi

exit 0
