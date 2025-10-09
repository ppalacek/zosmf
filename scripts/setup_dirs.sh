#!/bin/sh
#
# setup_dirs.sh - Create USS directory structure for workflow
#
# This script creates the necessary USS directories for the workflow
# and sets appropriate permissions.
#
# Usage: ./setup_dirs.sh [work_dir] [owner]
#
# Parameters:
#   work_dir - Base working directory (default: current user's home/workflow)
#   owner    - Directory owner (default: current user)
#

# Set default values
WORK_DIR="${1:-/u/$(whoami)/workflow}"
OWNER="${2:-$(whoami)}"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to create directory with error handling
create_directory() {
    local dir_path="$1"
    local permissions="$2"
    
    if [ ! -d "$dir_path" ]; then
        log_message "Creating directory: $dir_path"
        mkdir -p "$dir_path"
        if [ $? -eq 0 ]; then
            chmod "$permissions" "$dir_path"
            log_message "Successfully created $dir_path with permissions $permissions"
        else
            log_message "ERROR: Failed to create directory $dir_path"
            return 1
        fi
    else
        log_message "Directory already exists: $dir_path"
    fi
    return 0
}

# Start directory setup
log_message "Starting USS directory setup"
log_message "Base work directory: $WORK_DIR"
log_message "Owner: $OWNER"

# Create main working directory
create_directory "$WORK_DIR" "755"

# Create subdirectories
create_directory "$WORK_DIR/scripts" "755"
create_directory "$WORK_DIR/jcl" "755"
create_directory "$WORK_DIR/python" "755"
create_directory "$WORK_DIR/rexx" "755"
create_directory "$WORK_DIR/logs" "755"
create_directory "$WORK_DIR/output" "755"
create_directory "$WORK_DIR/temp" "755"
create_directory "$WORK_DIR/backup" "755"
create_directory "$WORK_DIR/config" "755"
create_directory "$WORK_DIR/data" "755"

# Create specific subdirectories for organization
create_directory "$WORK_DIR/scripts/utilities" "755"
create_directory "$WORK_DIR/scripts/validation" "755"
create_directory "$WORK_DIR/python/modules" "755"
create_directory "$WORK_DIR/python/site-packages" "755"
create_directory "$WORK_DIR/logs/workflow" "755"
create_directory "$WORK_DIR/logs/jobs" "755"
create_directory "$WORK_DIR/output/reports" "755"
create_directory "$WORK_DIR/output/datasets" "755"

# Create initial configuration files
log_message "Creating initial configuration files"

# Create environment configuration
cat > "$WORK_DIR/config/environment.conf" << EOF
# Environment Configuration
WORKFLOW_VERSION=1.0.0
WORKFLOW_HOME=$WORK_DIR
WORKFLOW_OWNER=$OWNER
WORKFLOW_SETUP_DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Directory paths
SCRIPT_DIR=$WORK_DIR/scripts
JCL_DIR=$WORK_DIR/jcl
PYTHON_DIR=$WORK_DIR/python
LOG_DIR=$WORK_DIR/logs
OUTPUT_DIR=$WORK_DIR/output
TEMP_DIR=$WORK_DIR/temp
BACKUP_DIR=$WORK_DIR/backup

# Default permissions
DIR_PERMISSIONS=755
FILE_PERMISSIONS=644
SCRIPT_PERMISSIONS=755

# Logging configuration
LOG_LEVEL=INFO
LOG_RETENTION_DAYS=30
MAX_LOG_SIZE=10MB

# System paths
PYTHON_PATH=/usr/lpp/IBM/cyp/v3r9/pyz/bin/python3
REXX_PATH=/usr/lpp/IBM/zosmf/bin
EOF

# Create workflow status file
cat > "$WORK_DIR/config/workflow_status.conf" << EOF
# Workflow Status Configuration
STATUS=INITIALIZED
SETUP_COMPLETE=YES
SETUP_DATE=$(date '+%Y-%m-%d %H:%M:%S')
LAST_UPDATE=$(date '+%Y-%m-%d %H:%M:%S')
DIRECTORIES_CREATED=YES
PERMISSIONS_SET=YES
CONFIG_FILES_CREATED=YES
EOF

# Set permissions on configuration files
chmod 644 "$WORK_DIR/config/environment.conf"
chmod 644 "$WORK_DIR/config/workflow_status.conf"

# Create a simple validation script
cat > "$WORK_DIR/scripts/validate_setup.sh" << 'EOF'
#!/bin/sh
#
# validate_setup.sh - Validate USS directory setup
#

WORK_DIR="${1:-/u/$(whoami)/workflow}"

echo "Validating USS directory setup..."
echo "Base directory: $WORK_DIR"

# Check if directories exist
directories="scripts jcl python logs output temp backup config data"

for dir in $directories; do
    if [ -d "$WORK_DIR/$dir" ]; then
        echo "✓ Directory exists: $dir"
    else
        echo "✗ Directory missing: $dir"
    fi
done

# Check permissions
echo ""
echo "Directory permissions:"
ls -la "$WORK_DIR"

echo ""
echo "Validation complete."
EOF

chmod 755 "$WORK_DIR/scripts/validate_setup.sh"

# Create log entry
log_message "USS directory setup completed successfully"
log_message "Created directories under: $WORK_DIR"
log_message "Configuration files created in: $WORK_DIR/config"
log_message "Validation script available: $WORK_DIR/scripts/validate_setup.sh"

# Create initial log file
LOG_FILE="$WORK_DIR/logs/setup.log"
{
    echo "=== USS Directory Setup Log ==="
    echo "Setup Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Work Directory: $WORK_DIR"
    echo "Owner: $OWNER"
    echo "Script: $0"
    echo "=== Directories Created ==="
    find "$WORK_DIR" -type d | sort
    echo "=== Setup Complete ==="
} > "$LOG_FILE"

echo ""
echo "USS directory setup completed successfully!"
echo "Log file created: $LOG_FILE"
echo "To validate setup, run: $WORK_DIR/scripts/validate_setup.sh"
echo ""

exit 0