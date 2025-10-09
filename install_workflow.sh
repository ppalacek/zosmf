#!/bin/sh
#
# install_workflow.sh - Install zOSMF workflow on target system
#
# This script uploads and configures the workflow on the target z/OS system
# It handles file transfers, permission setting, and workflow registration
#
# Usage: ./install_workflow.sh [target_user] [target_system] [work_dir]
#
# Parameters:
#   target_user   - Target system user ID (default: current user)
#   target_system - Target z/OS system hostname/IP
#   work_dir      - Target working directory (default: /u/user/workflow)
#

# Set default values
TARGET_USER="${1:-$(whoami)}"
TARGET_SYSTEM="${2:-localhost}"
WORK_DIR="${3:-/u/$TARGET_USER/workflow}"

# Local source directories
SOURCE_DIR="$(dirname "$0")/.."
JCL_SOURCE="$SOURCE_DIR/jcl"
SCRIPTS_SOURCE="$SOURCE_DIR/scripts"
PYTHON_SOURCE="$SOURCE_DIR/python"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check prerequisites
check_prerequisites() {
    log_message "Checking installation prerequisites..."
    
    # Check if source files exist
    if [ ! -f "$SOURCE_DIR/workflow-definition.xml" ]; then
        log_message "ERROR: workflow-definition.xml not found in $SOURCE_DIR"
        return 1
    fi
    
    if [ ! -d "$JCL_SOURCE" ]; then
        log_message "ERROR: JCL source directory not found: $JCL_SOURCE"
        return 1
    fi
    
    if [ ! -d "$SCRIPTS_SOURCE" ]; then
        log_message "ERROR: Scripts source directory not found: $SCRIPTS_SOURCE"
        return 1
    fi
    
    # Check connectivity to target system (if not localhost)
    if [ "$TARGET_SYSTEM" != "localhost" ]; then
        log_message "Testing connectivity to $TARGET_SYSTEM..."
        if ! ping -c 1 "$TARGET_SYSTEM" >/dev/null 2>&1; then
            log_message "WARNING: Cannot ping target system $TARGET_SYSTEM"
        fi
    fi
    
    log_message "Prerequisites check completed"
    return 0
}

# Function to create remote directories
create_remote_directories() {
    log_message "Creating remote directory structure on $TARGET_SYSTEM..."
    
    # Define directories to create
    directories="
        $WORK_DIR
        $WORK_DIR/scripts
        $WORK_DIR/jcl
        $WORK_DIR/python
        $WORK_DIR/logs
        $WORK_DIR/output
        $WORK_DIR/config
        $WORK_DIR/backup
        $WORK_DIR/temp
    "
    
    for dir in $directories; do
        if [ "$TARGET_SYSTEM" = "localhost" ]; then
            # Local installation
            mkdir -p "$dir"
            chmod 755 "$dir"
            log_message "Created local directory: $dir"
        else
            # Remote installation
            ssh "$TARGET_USER@$TARGET_SYSTEM" "mkdir -p '$dir' && chmod 755 '$dir'"
            if [ $? -eq 0 ]; then
                log_message "Created remote directory: $dir"
            else
                log_message "ERROR: Failed to create remote directory: $dir"
                return 1
            fi
        fi
    done
    
    log_message "Directory structure created successfully"
    return 0
}

# Function to upload files
upload_files() {
    log_message "Uploading workflow files to $TARGET_SYSTEM..."
    
    if [ "$TARGET_SYSTEM" = "localhost" ]; then
        # Local installation - copy files
        log_message "Performing local file copy..."
        
        # Copy main workflow files
        cp "$SOURCE_DIR/workflow-definition.xml" "$WORK_DIR/"
        cp "$SOURCE_DIR/workflow.properties" "$WORK_DIR/config/"
        cp "$SOURCE_DIR/variables.properties" "$WORK_DIR/config/"
        
        # Copy JCL files
        cp -r "$JCL_SOURCE"/* "$WORK_DIR/jcl/"
        
        # Copy scripts
        cp -r "$SCRIPTS_SOURCE"/* "$WORK_DIR/scripts/"
        
        # Copy Python files
        if [ -d "$PYTHON_SOURCE" ]; then
            cp -r "$PYTHON_SOURCE"/* "$WORK_DIR/python/"
        fi
        
        log_message "Local file copy completed"
    else
        # Remote installation - use scp
        log_message "Performing remote file transfer..."
        
        # Upload main workflow files
        scp "$SOURCE_DIR/workflow-definition.xml" "$TARGET_USER@$TARGET_SYSTEM:$WORK_DIR/"
        scp "$SOURCE_DIR/workflow.properties" "$TARGET_USER@$TARGET_SYSTEM:$WORK_DIR/config/"
        scp "$SOURCE_DIR/variables.properties" "$TARGET_USER@$TARGET_SYSTEM:$WORK_DIR/config/"
        
        # Upload JCL files
        scp -r "$JCL_SOURCE"/* "$TARGET_USER@$TARGET_SYSTEM:$WORK_DIR/jcl/"
        
        # Upload scripts
        scp -r "$SCRIPTS_SOURCE"/* "$TARGET_USER@$TARGET_SYSTEM:$WORK_DIR/scripts/"
        
        # Upload Python files
        if [ -d "$PYTHON_SOURCE" ]; then
            scp -r "$PYTHON_SOURCE"/* "$TARGET_USER@$TARGET_SYSTEM:$WORK_DIR/python/"
        fi
        
        log_message "Remote file transfer completed"
    fi
    
    return 0
}

# Function to set permissions
set_permissions() {
    log_message "Setting file permissions..."
    
    if [ "$TARGET_SYSTEM" = "localhost" ]; then
        # Local permission setting
        find "$WORK_DIR" -type f -name "*.sh" -exec chmod 755 {} \;
        find "$WORK_DIR" -type f -name "*.py" -exec chmod 755 {} \;
        find "$WORK_DIR" -type f -name "*.jcl" -exec chmod 644 {} \;
        find "$WORK_DIR" -type f -name "*.xml" -exec chmod 644 {} \;
        find "$WORK_DIR" -type f -name "*.properties" -exec chmod 644 {} \;
        
        log_message "Local permissions set"
    else
        # Remote permission setting
        ssh "$TARGET_USER@$TARGET_SYSTEM" "
            find '$WORK_DIR' -type f -name '*.sh' -exec chmod 755 {} \;
            find '$WORK_DIR' -type f -name '*.py' -exec chmod 755 {} \;
            find '$WORK_DIR' -type f -name '*.jcl' -exec chmod 644 {} \;
            find '$WORK_DIR' -type f -name '*.xml' -exec chmod 644 {} \;
            find '$WORK_DIR' -type f -name '*.properties' -exec chmod 644 {} \;
        "
        
        log_message "Remote permissions set"
    fi
    
    return 0
}

# Function to configure workflow
configure_workflow() {
    log_message "Configuring workflow for target environment..."
    
    # Create installation configuration
    config_content="# Workflow Installation Configuration
INSTALLATION_DATE=$(date '+%Y-%m-%d %H:%M:%S')
INSTALLATION_USER=$(whoami)
TARGET_USER=$TARGET_USER
TARGET_SYSTEM=$TARGET_SYSTEM
WORKFLOW_HOME=$WORK_DIR
INSTALLATION_SOURCE=$SOURCE_DIR

# File locations
WORKFLOW_DEFINITION=$WORK_DIR/workflow-definition.xml
WORKFLOW_PROPERTIES=$WORK_DIR/config/workflow.properties
VARIABLES_PROPERTIES=$WORK_DIR/config/variables.properties

# Status
INSTALLATION_STATUS=COMPLETED
CONFIGURATION_STATUS=COMPLETED
"

    if [ "$TARGET_SYSTEM" = "localhost" ]; then
        echo "$config_content" > "$WORK_DIR/config/installation.conf"
    else
        echo "$config_content" | ssh "$TARGET_USER@$TARGET_SYSTEM" "cat > '$WORK_DIR/config/installation.conf'"
    fi
    
    log_message "Workflow configuration completed"
    return 0
}

# Function to validate installation
validate_installation() {
    log_message "Validating installation..."
    
    validation_script="$WORK_DIR/scripts/validate_setup.sh"
    
    if [ "$TARGET_SYSTEM" = "localhost" ]; then
        if [ -x "$validation_script" ]; then
            log_message "Running local validation..."
            "$validation_script" "$WORK_DIR"
        else
            log_message "WARNING: Validation script not found or not executable"
        fi
    else
        log_message "Running remote validation..."
        ssh "$TARGET_USER@$TARGET_SYSTEM" "
            if [ -x '$validation_script' ]; then
                '$validation_script' '$WORK_DIR'
            else
                echo 'WARNING: Validation script not found or not executable'
            fi
        "
    fi
    
    return 0
}

# Function to display installation summary
display_summary() {
    log_message "=== Installation Summary ==="
    log_message "Target User: $TARGET_USER"
    log_message "Target System: $TARGET_SYSTEM"
    log_message "Work Directory: $WORK_DIR"
    log_message "Source Directory: $SOURCE_DIR"
    log_message ""
    log_message "Files installed:"
    log_message "  - Workflow Definition: $WORK_DIR/workflow-definition.xml"
    log_message "  - Configuration Files: $WORK_DIR/config/"
    log_message "  - JCL Templates: $WORK_DIR/jcl/"
    log_message "  - Shell Scripts: $WORK_DIR/scripts/"
    log_message "  - Python Scripts: $WORK_DIR/python/"
    log_message ""
    log_message "Next steps:"
    log_message "1. Register workflow with zOSMF:"
    log_message "   - Access zOSMF Workflows interface"
    log_message "   - Register new workflow using: $WORK_DIR/workflow-definition.xml"
    log_message "2. Configure workflow parameters as needed"
    log_message "3. Test workflow execution"
    log_message ""
    log_message "Installation completed successfully!"
}

# Function to create quick start guide
create_quick_start() {
    log_message "Creating quick start guide..."
    
    quick_start_content="# zOSMF Workflow Quick Start Guide

## Installation Summary
- Installation Date: $(date '+%Y-%m-%d %H:%M:%S')
- Target User: $TARGET_USER
- Target System: $TARGET_SYSTEM
- Work Directory: $WORK_DIR

## File Structure
\`\`\`
$WORK_DIR/
├── workflow-definition.xml     # Main workflow definition
├── config/                     # Configuration files
│   ├── workflow.properties
│   ├── variables.properties
│   └── installation.conf
├── jcl/                       # JCL templates
│   ├── create_datasets.jcl
│   ├── process_data.jcl
│   └── cleanup.jcl
├── scripts/                   # Shell scripts
│   ├── setup_dirs.sh
│   ├── run_python.sh
│   └── validate_results.sh
├── python/                    # Python scripts
│   ├── data_processor.py
│   └── workflow_utilities.py
├── logs/                      # Log files
├── output/                    # Output files
└── backup/                    # Backup files
\`\`\`

## Next Steps

### 1. Register Workflow with zOSMF
1. Open zOSMF interface in web browser
2. Navigate to Workflows
3. Click 'Register Workflow'
4. Specify workflow definition file: $WORK_DIR/workflow-definition.xml
5. Set workflow properties as needed

### 2. Configure Parameters
Edit the following files to match your environment:
- $WORK_DIR/config/workflow.properties
- $WORK_DIR/config/variables.properties

### 3. Test Installation
Run validation script:
\`\`\`bash
$WORK_DIR/scripts/validate_setup.sh $WORK_DIR
\`\`\`

### 4. Execute Workflow
1. Start workflow instance in zOSMF
2. Provide required parameters:
   - WORKFLOW_OWNER: Your TSO user ID
   - JOB_PREFIX: Job name prefix (3-4 chars)
   - HLQ: Dataset high level qualifier
   - USS_WORK_DIR: $WORK_DIR
   - ENVIRONMENT: DEV/TEST/PROD
3. Execute workflow steps

### 5. Monitor Execution
- Check logs in: $WORK_DIR/logs/
- Check outputs in: $WORK_DIR/output/
- Monitor job execution through zOSMF

## Troubleshooting
- Check installation log for errors
- Verify file permissions are correct
- Ensure all required directories exist
- Validate TSO and USS access

## Support Files
- Installation log: Check terminal output
- Validation script: $WORK_DIR/scripts/validate_setup.sh
- Configuration: $WORK_DIR/config/installation.conf
"

    if [ "$TARGET_SYSTEM" = "localhost" ]; then
        echo "$quick_start_content" > "$WORK_DIR/QUICK_START.md"
    else
        echo "$quick_start_content" | ssh "$TARGET_USER@$TARGET_SYSTEM" "cat > '$WORK_DIR/QUICK_START.md'"
    fi
    
    log_message "Quick start guide created: $WORK_DIR/QUICK_START.md"
}

# Main installation function
main() {
    log_message "=== Starting zOSMF Workflow Installation ==="
    log_message "Target User: $TARGET_USER"
    log_message "Target System: $TARGET_SYSTEM"
    log_message "Work Directory: $WORK_DIR"
    log_message "Source Directory: $SOURCE_DIR"
    
    # Step 1: Check prerequisites
    if ! check_prerequisites; then
        log_message "ERROR: Prerequisites check failed"
        exit 1
    fi
    
    # Step 2: Create directories
    if ! create_remote_directories; then
        log_message "ERROR: Failed to create remote directories"
        exit 1
    fi
    
    # Step 3: Upload files
    if ! upload_files; then
        log_message "ERROR: Failed to upload files"
        exit 1
    fi
    
    # Step 4: Set permissions
    if ! set_permissions; then
        log_message "ERROR: Failed to set permissions"
        exit 1
    fi
    
    # Step 5: Configure workflow
    if ! configure_workflow; then
        log_message "ERROR: Failed to configure workflow"
        exit 1
    fi
    
    # Step 6: Validate installation
    validate_installation
    
    # Step 7: Create documentation
    create_quick_start
    
    # Step 8: Display summary
    display_summary
    
    log_message "=== Installation completed successfully ==="
    exit 0
}

# Execute main function
main "$@"