#!/bin/sh
#
# register_workflow.sh - Register workflow with zOSMF
#
# This script registers the workflow with zOSMF using REST API calls
# It handles workflow registration, property setting, and initial validation
#
# Usage: ./register_workflow.sh [zosmf_host] [zosmf_port] [user] [work_dir]
#
# Parameters:
#   zosmf_host - zOSMF host (default: localhost)
#   zosmf_port - zOSMF port (default: 443)
#   user       - User ID for authentication
#   work_dir   - Workflow working directory
#

# Set default values
ZOSMF_HOST="${1:-localhost}"
ZOSMF_PORT="${2:-443}"
USER="${3:-$(whoami)}"
WORK_DIR="${4:-/u/$USER/workflow}"

# Configuration
WORKFLOW_NAME="BASELINE_WORKFLOW_TEST"
WORKFLOW_VERSION="1.0.0"
WORKFLOW_DEF_FILE="$WORK_DIR/workflow-definition.xml"
WORKFLOW_PROPS_FILE="$WORK_DIR/config/workflow.properties"

# zOSMF API endpoints
ZOSMF_BASE_URL="https://$ZOSMF_HOST:$ZOSMF_PORT/zosmf"
WORKFLOWS_API="$ZOSMF_BASE_URL/workflow/rest/1.0/workflows"
AUTH_API="$ZOSMF_BASE_URL/info"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check zOSMF connectivity
check_zosmf_connectivity() {
    log_message "Checking zOSMF connectivity to $ZOSMF_HOST:$ZOSMF_PORT..."
    
    # Test basic connectivity
    if ! nc -z "$ZOSMF_HOST" "$ZOSMF_PORT" 2>/dev/null; then
        log_message "ERROR: Cannot connect to zOSMF at $ZOSMF_HOST:$ZOSMF_PORT"
        return 1
    fi
    
    log_message "zOSMF connectivity confirmed"
    return 0
}

# Function to authenticate with zOSMF
authenticate_zosmf() {
    log_message "Authenticating with zOSMF..."
    
    # Prompt for password
    echo -n "Enter password for user $USER: "
    read -s PASSWORD
    echo
    
    # Test authentication
    auth_response=$(curl -s -k -u "$USER:$PASSWORD" \
        -H "Content-Type: application/json" \
        "$AUTH_API" 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$auth_response" | grep -q "zosmf_version"; then
        log_message "Authentication successful"
        export ZOSMF_AUTH="$USER:$PASSWORD"
        return 0
    else
        log_message "ERROR: Authentication failed"
        return 1
    fi
}

# Function to check if workflow already exists
check_existing_workflow() {
    log_message "Checking for existing workflow: $WORKFLOW_NAME"
    
    response=$(curl -s -k -u "$ZOSMF_AUTH" \
        -H "Content-Type: application/json" \
        "$WORKFLOWS_API" 2>/dev/null)
    
    if echo "$response" | grep -q "$WORKFLOW_NAME"; then
        log_message "WARNING: Workflow $WORKFLOW_NAME already exists"
        echo -n "Do you want to delete the existing workflow? (y/n): "
        read answer
        
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            delete_existing_workflow
        else
            log_message "Keeping existing workflow - registration aborted"
            return 1
        fi
    fi
    
    return 0
}

# Function to delete existing workflow
delete_existing_workflow() {
    log_message "Deleting existing workflow: $WORKFLOW_NAME"
    
    # Get workflow key
    workflow_key=$(curl -s -k -u "$ZOSMF_AUTH" \
        -H "Content-Type: application/json" \
        "$WORKFLOWS_API" | \
        grep -A 10 "$WORKFLOW_NAME" | \
        grep "workflowKey" | \
        sed 's/.*"workflowKey":"\([^"]*\)".*/\1/')
    
    if [ -n "$workflow_key" ]; then
        delete_response=$(curl -s -k -u "$ZOSMF_AUTH" \
            -X DELETE \
            -H "Content-Type: application/json" \
            "$WORKFLOWS_API/$workflow_key")
        
        if [ $? -eq 0 ]; then
            log_message "Existing workflow deleted successfully"
        else
            log_message "ERROR: Failed to delete existing workflow"
            return 1
        fi
    else
        log_message "WARNING: Could not find workflow key for deletion"
    fi
    
    return 0
}

# Function to validate workflow definition file
validate_workflow_definition() {
    log_message "Validating workflow definition file: $WORKFLOW_DEF_FILE"
    
    if [ ! -f "$WORKFLOW_DEF_FILE" ]; then
        log_message "ERROR: Workflow definition file not found: $WORKFLOW_DEF_FILE"
        return 1
    fi
    
    # Basic XML validation
    if ! grep -q "<?xml" "$WORKFLOW_DEF_FILE"; then
        log_message "ERROR: Invalid XML format in workflow definition"
        return 1
    fi
    
    if ! grep -q "<workflow" "$WORKFLOW_DEF_FILE"; then
        log_message "ERROR: Missing workflow element in definition"
        return 1
    fi
    
    # Check for required elements
    required_elements="workflowInfo workflowID workflowDescription"
    for element in $required_elements; do
        if ! grep -q "<$element>" "$WORKFLOW_DEF_FILE"; then
            log_message "WARNING: Missing required element: $element"
        fi
    done
    
    log_message "Workflow definition validation completed"
    return 0
}

# Function to register workflow
register_workflow() {
    log_message "Registering workflow with zOSMF..."
    
    # Create registration request
    registration_json=$(cat << EOF
{
    "workflowName": "$WORKFLOW_NAME",
    "workflowDefinitionFile": "$WORKFLOW_DEF_FILE",
    "workflowDescription": "Baseline zOS Workflow for Testing Multiple Technologies",
    "workflowVersion": "$WORKFLOW_VERSION",
    "vendor": "Custom Development",
    "category": "Testing",
    "owner": "$USER",
    "system": "$ZOSMF_HOST"
}
EOF
)
    
    # Submit registration request
    response=$(curl -s -k -u "$ZOSMF_AUTH" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$registration_json" \
        "$WORKFLOWS_API")
    
    if [ $? -eq 0 ]; then
        # Check response for success
        if echo "$response" | grep -q "workflowKey"; then
            workflow_key=$(echo "$response" | \
                grep "workflowKey" | \
                sed 's/.*"workflowKey":"\([^"]*\)".*/\1/')
            
            log_message "Workflow registered successfully"
            log_message "Workflow Key: $workflow_key"
            
            # Save workflow key for later use
            echo "WORKFLOW_KEY=$workflow_key" > "$WORK_DIR/config/workflow_registration.conf"
            echo "REGISTRATION_DATE=$(date '+%Y-%m-%d %H:%M:%S')" >> "$WORK_DIR/config/workflow_registration.conf"
            echo "ZOSMF_HOST=$ZOSMF_HOST" >> "$WORK_DIR/config/workflow_registration.conf"
            echo "ZOSMF_PORT=$ZOSMF_PORT" >> "$WORK_DIR/config/workflow_registration.conf"
            
            return 0
        else
            log_message "ERROR: Workflow registration failed"
            log_message "Response: $response"
            return 1
        fi
    else
        log_message "ERROR: Failed to communicate with zOSMF"
        return 1
    fi
}

# Function to set workflow properties
set_workflow_properties() {
    log_message "Setting workflow properties..."
    
    if [ ! -f "$WORKFLOW_PROPS_FILE" ]; then
        log_message "WARNING: Workflow properties file not found: $WORKFLOW_PROPS_FILE"
        return 0
    fi
    
    # Read workflow key
    if [ -f "$WORK_DIR/config/workflow_registration.conf" ]; then
        . "$WORK_DIR/config/workflow_registration.conf"
    else
        log_message "ERROR: Workflow registration configuration not found"
        return 1
    fi
    
    # Create properties JSON from file
    properties_json="{"
    first=true
    
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        case "$key" in
            \#*|'') continue ;;
        esac
        
        if [ "$first" = true ]; then
            first=false
        else
            properties_json="${properties_json},"
        fi
        
        properties_json="${properties_json}\"$key\":\"$value\""
    done < "$WORKFLOW_PROPS_FILE"
    
    properties_json="${properties_json}}"
    
    # Update workflow properties
    prop_response=$(curl -s -k -u "$ZOSMF_AUTH" \
        -X PUT \
        -H "Content-Type: application/json" \
        -d "$properties_json" \
        "$WORKFLOWS_API/$WORKFLOW_KEY/properties")
    
    if [ $? -eq 0 ]; then
        log_message "Workflow properties updated successfully"
        return 0
    else
        log_message "WARNING: Failed to update workflow properties"
        return 1
    fi
}

# Function to validate registration
validate_registration() {
    log_message "Validating workflow registration..."
    
    # Read workflow key
    if [ -f "$WORK_DIR/config/workflow_registration.conf" ]; then
        . "$WORK_DIR/config/workflow_registration.conf"
    else
        log_message "ERROR: Workflow registration configuration not found"
        return 1
    fi
    
    # Get workflow details
    details_response=$(curl -s -k -u "$ZOSMF_AUTH" \
        -H "Content-Type: application/json" \
        "$WORKFLOWS_API/$WORKFLOW_KEY")
    
    if [ $? -eq 0 ] && echo "$details_response" | grep -q "$WORKFLOW_NAME"; then
        log_message "Workflow registration validated successfully"
        
        # Extract and display key information
        status=$(echo "$details_response" | grep "workflowStatus" | sed 's/.*"workflowStatus":"\([^"]*\)".*/\1/')
        log_message "Workflow Status: $status"
        
        return 0
    else
        log_message "ERROR: Workflow registration validation failed"
        return 1
    fi
}

# Function to display registration summary
display_registration_summary() {
    log_message "=== Workflow Registration Summary ==="
    
    if [ -f "$WORK_DIR/config/workflow_registration.conf" ]; then
        . "$WORK_DIR/config/workflow_registration.conf"
        
        log_message "Workflow Name: $WORKFLOW_NAME"
        log_message "Workflow Key: $WORKFLOW_KEY"
        log_message "zOSMF Host: $ZOSMF_HOST"
        log_message "zOSMF Port: $ZOSMF_PORT"
        log_message "Registration Date: $REGISTRATION_DATE"
        log_message "Owner: $USER"
        log_message ""
        log_message "Access URL: https://$ZOSMF_HOST:$ZOSMF_PORT/zosmf/workflows"
        log_message ""
        log_message "Next steps:"
        log_message "1. Access zOSMF Workflows interface"
        log_message "2. Locate workflow: $WORKFLOW_NAME"
        log_message "3. Create workflow instance"
        log_message "4. Configure instance parameters"
        log_message "5. Execute workflow steps"
    else
        log_message "ERROR: Registration configuration not found"
        return 1
    fi
    
    log_message "=== Registration completed successfully ==="
}

# Main registration function
main() {
    log_message "=== Starting zOSMF Workflow Registration ==="
    log_message "zOSMF Host: $ZOSMF_HOST"
    log_message "zOSMF Port: $ZOSMF_PORT"
    log_message "User: $USER"
    log_message "Work Directory: $WORK_DIR"
    log_message "Workflow Name: $WORKFLOW_NAME"
    
    # Step 1: Check zOSMF connectivity
    if ! check_zosmf_connectivity; then
        exit 1
    fi
    
    # Step 2: Authenticate
    if ! authenticate_zosmf; then
        exit 1
    fi
    
    # Step 3: Validate workflow definition
    if ! validate_workflow_definition; then
        exit 1
    fi
    
    # Step 4: Check for existing workflow
    if ! check_existing_workflow; then
        exit 1
    fi
    
    # Step 5: Register workflow
    if ! register_workflow; then
        exit 1
    fi
    
    # Step 6: Set properties
    set_workflow_properties
    
    # Step 7: Validate registration
    if ! validate_registration; then
        exit 1
    fi
    
    # Step 8: Display summary
    display_registration_summary
    
    exit 0
}

# Execute main function
main "$@"