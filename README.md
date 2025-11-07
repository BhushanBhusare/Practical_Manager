Practical Management Software (Bash Edition)
✨ Project Overview
This is a robust, multi-user assignment management system built entirely using Bash scripting. It's designed specifically for college lab environments where multiple students use the same terminal or machine for practical work.

The software centralizes assignment workflow, guarantees file integrity, and automates the preparation of code for submission.

🔑 Key Features
👥 Multi-User Isolation: Supports multiple student profiles on a single machine, ensuring each user has segregated paths for their code and metadata.

💾 Guaranteed Local Access: Code files are stored directly on the user's desktop (~/Desktop/USERNAME_Practicals/) for easy GUI access and editing.

🔒 Secure Setup & Permissions: The setup process safely uses sudo once to install dependencies and fix file ownership, preventing the common "Permission Denied" errors and file locking.

🐞 Debugging Workflow: The run command compiles code and displays the full execution output directly on the terminal for immediate debugging, while saving a record to the assignment's log file.

📧 Submission Automation: The mail feature generates a single, consolidated .txt submission file (containing the header, full source code, and last execution output) and emails it via a configured Mutt client.

🚀 Getting Started
Prerequisites
You must be running a Debian-based Linux distribution (like Ubuntu or Kali) to use apt for package installation.

# Setup :

1. Clone the Project    
    git clone ( git clone https://github.com/BhushanBhusare/Practical_Manager.git && cd Practical_Manager )

2. Run Initial Setup (System-Wide)
The first time this project is run on a machine, it requires sudo to install necessary packages (gcc, mutt, gedit) and set the file permissions correctly.

   ( ''' Set scripts as executable
    chmod +x setup.sh Practical_manager.sh core_setup.sh )

    Run the setup script
    (sudo bash setup.sh)

3. Launch and Create Your Profile
After the setup is complete, run the application as a normal user (without sudo). The application will guide you through creating your unique profile.


    ./Practical_manager.sh






