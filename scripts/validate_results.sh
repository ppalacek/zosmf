#!/bin/sh
#
# validate_results.sh - Validate workflow execution results
#
# This script validates the results of workflow execution by checking
# job outputs, dataset contents, and overall workflow status
#
# Usage: ./validate_results.sh [work_dir] [hlq] [environment]
#
# Parameters:
#   work_dir    - Working directory (default: current user's home/workflow)
#   hlq         - High level qualifier for datasets
#   environment - Target environment (DEV/TEST/PROD)
#

# Set default values
WORK_DIR="${1:-/u/$(whoami)/workflow}"
HLQ="${2:-$(whoami | tr '[a-z]' '[A-Z]')}"
ENVIRONMENT="${3:-TEST}"

# Configuration
LOG_DIR="$WORK_DIR/logs"
OUTPUT_DIR="$WORK_DIR/output"
BACKUP_DIR="$WORK_DIR/backup"
CONFIG_DIR="$WORK_DIR/config"

# Validation results
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Function to log messages with severity
log_message() {
    local severity="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$LOG_DIR/validation.log"
    
    echo "$timestamp [$severity] $message" | tee -a "$log_file"
    
    case "$severity" in
        "ERROR")
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            ;;
        "WARNING")
            VALIDATION_WARNINGS=$((VALIDATION_WARNINGS + 1))
            ;;
    esac
}

# Function to check if dataset exists
check_dataset() {
    local dataset="$1"
    local description="$2"
    local required="$3"
    
    # Use TSO LISTCAT to check dataset existence
    if echo "LISTCAT ENT('$dataset')" | tso 2>/dev/null | grep -q "$dataset"; then
        log_message "INFO" "Dataset exists: $dataset ($description)"
        return 0
    else
        if [ "$required" = "true" ]; then
            log_message "ERROR" "Required dataset missing: $dataset ($description)"
        else
            log_message "WARNING" "Optional dataset missing: $dataset ($description)"
        fi
        return 1
    fi
}

# Function to check USS file/directory
check_uss_path() {
    local path="$1"
    local description="$2"
    local required="$3"
    local type="$4"  # file or directory
    
    if [ "$type" = "directory" ]; then
        if [ -d "$path" ]; then
            log_message "INFO" "Directory exists: $path ($description)"
            return 0
        fi
    else
        if [ -f "$path" ]; then
            log_message "INFO" "File exists: $path ($description)"
            # Check if file has content
            if [ -s "$path" ]; then
                log_message "INFO" "File has content: $path"
            else
                log_message "WARNING" "File is empty: $path"
            fi
            return 0
        fi
    fi
    
    if [ "$required" = "true" ]; then
        log_message "ERROR" "$type missing: $path ($description)"
    else
        log_message "WARNING" "Optional $type missing: $path ($description)"
    fi
    return 1
}

# Function to validate job outputs
validate_job_outputs() {
    log_message "INFO" "=== Validating Job Outputs ==="
    
    # Check for job output datasets
    check_dataset "$HLQ.WORK.DATA" "Work dataset" "true"
    check_dataset "$HLQ.LOG.$ENVIRONMENT" "Log dataset" "true"
    check_dataset "$HLQ.BACKUP.$ENVIRONMENT" "Backup dataset" "true"
    check_dataset "$HLQ.CONTROL.CARDS" "Control dataset" "false"
    
    # Environment-specific validation
    case "$ENVIRONMENT" in
        "PROD")
            check_dataset "$HLQ.BACKUP.PROD.COPY2" "Production backup copy" "false"
            ;;
    esac
    
    # Check for archived datasets
    echo "LISTCAT LEVEL('$HLQ') ALL" | tso 2>/dev/null | grep "ARCHIVE" | while read dataset; do
        log_message "INFO" "Archive dataset found: $dataset"
    done
}

# Function to validate USS files
validate_uss_files() {
    log_message "INFO" "=== Validating USS Files ==="
    
    # Check required directories
    check_uss_path "$WORK_DIR" "Main work directory" "true" "directory"
    check_uss_path "$LOG_DIR" "Log directory" "true" "directory"
    check_uss_path "$OUTPUT_DIR" "Output directory" "true" "directory"
    check_uss_path "$CONFIG_DIR" "Config directory" "true" "directory"
    
    # Check configuration files
    check_uss_path "$CONFIG_DIR/environment.conf" "Environment config" "true" "file"
    check_uss_path "$CONFIG_DIR/workflow_status.conf" "Status config" "true" "file"
    
    # Check log files
    check_uss_path "$LOG_DIR/setup.log" "Setup log" "false" "file"
    check_uss_path "$LOG_DIR/validation.log" "Validation log" "true" "file"
    
    # Check for Python output files
    if [ -d "$OUTPUT_DIR" ]; then
        python_outputs=$(find "$OUTPUT_DIR" -name "python_output_*.txt" -type f | wc -l)
        if [ $python_outputs -gt 0 ]; then
            log_message "INFO" "Found $python_outputs Python output files"
        else
            log_message "WARNING" "No Python output files found"
        fi
    fi
}

# Function to validate file permissions
validate_permissions() {
    log_message "INFO" "=== Validating File Permissions ==="
    
    # Check directory permissions
    directories="$WORK_DIR $LOG_DIR $OUTPUT_DIR $CONFIG_DIR"
    for dir in $directories; do
        if [ -d "$dir" ]; then
            perms=$(ls -ld "$dir" | cut -c1-10)
            log_message "INFO" "Directory permissions: $dir = $perms"
            
            # Check if directory is writable
            if [ -w "$dir" ]; then
                log_message "INFO" "Directory is writable: $dir"
            else
                log_message "WARNING" "Directory is not writable: $dir"
            fi
        fi
    done
    
    # Check script permissions
    scripts="$WORK_DIR/scripts/*.sh"
    for script in $scripts; do
        if [ -f "$script" ]; then
            perms=$(ls -l "$script" | cut -c1-10)
            log_message "INFO" "Script permissions: $(basename $script) = $perms"
            
            if [ -x "$script" ]; then
                log_message "INFO" "Script is executable: $(basename $script)"
            else
                log_message "WARNING" "Script is not executable: $(basename $script)"
            fi
        fi
    done
}

# Function to validate workflow status
validate_workflow_status() {
    log_message "INFO" "=== Validating Workflow Status ==="
    
    status_file="$CONFIG_DIR/workflow_status.conf"
    if [ -f "$status_file" ]; then
        log_message "INFO" "Reading workflow status from: $status_file"
        
        # Extract status information
        status=$(grep "^STATUS=" "$status_file" | cut -d'=' -f2)
        setup_complete=$(grep "^SETUP_COMPLETE=" "$status_file" | cut -d'=' -f2)
        directories_created=$(grep "^DIRECTORIES_CREATED=" "$status_file" | cut -d'=' -f2)
        
        log_message "INFO" "Workflow status: $status"
        log_message "INFO" "Setup complete: $setup_complete"
        log_message "INFO" "Directories created: $directories_created"
        
        # Validate status values
        case "$status" in
            "INITIALIZED"|"RUNNING"|"COMPLETED"|"FAILED")
                log_message "INFO" "Status is valid: $status"
                ;;
            *)
                log_message "WARNING" "Unexpected status value: $status"
                ;;
        esac
    else
        log_message "ERROR" "Workflow status file not found: $status_file"
    fi
}

# Function to check system resources
validate_system_resources() {
    log_message "INFO" "=== Validating System Resources ==="
    
    # Check disk space
    df "$WORK_DIR" | tail -1 | while read filesystem blocks used available use mountpoint; do
        log_message "INFO" "Filesystem: $filesystem"
        log_message "INFO" "Available space: $available blocks"
        
        # Check if we have enough space (at least 100MB = 100000 blocks approximately)
        if [ "$available" -gt 100000 ]; then
            log_message "INFO" "Sufficient disk space available"
        else
            log_message "WARNING" "Low disk space: $available blocks available"
        fi
    done
    
    # Check memory usage
    if command -v ps >/dev/null 2>&1; then
        memory_info=$(ps -o pid,vsz,rss,comm -p $$ | tail -1)
        log_message "INFO" "Current process memory: $memory_info"
    fi
    
    # Check load average if available
    if [ -f /proc/loadavg ]; then
        load_avg=$(cat /proc/loadavg | cut -d' ' -f1-3)
        log_message "INFO" "System load average: $load_avg"
    fi
}

# Function to generate validation report
generate_validation_report() {
    log_message "INFO" "=== Generating Validation Report ==="
    
    report_file="$OUTPUT_DIR/validation_report_$(date '+%Y%m%d_%H%M%S').txt"
    
    {
        echo "========================================"
        echo "    WORKFLOW VALIDATION REPORT"
        echo "========================================"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Work Directory: $WORK_DIR"
        echo "HLQ: $HLQ"
        echo "Environment: $ENVIRONMENT"
        echo ""
        echo "VALIDATION SUMMARY:"
        echo "  Errors: $VALIDATION_ERRORS"
        echo "  Warnings: $VALIDATION_WARNINGS"
        echo ""
        
        if [ $VALIDATION_ERRORS -eq 0 ]; then
            echo "OVERALL STATUS: PASSED"
            if [ $VALIDATION_WARNINGS -eq 0 ]; then
                echo "RESULT: All validations passed successfully"
            else
                echo "RESULT: Passed with $VALIDATION_WARNINGS warnings"
            fi
        else
            echo "OVERALL STATUS: FAILED"
            echo "RESULT: $VALIDATION_ERRORS errors found"
        fi
        
        echo ""
        echo "DETAILED LOG:"
        echo "See $LOG_DIR/validation.log for complete details"
        echo ""
        echo "========================================"
        echo "    END OF VALIDATION REPORT"
        echo "========================================"
    } > "$report_file"
    
    log_message "INFO" "Validation report created: $report_file"
    
    # Display report summary
    cat "$report_file"
}

# Main execution
main() {
    log_message "INFO" "=== Starting Workflow Validation ==="
    log_message "INFO" "Work Directory: $WORK_DIR"
    log_message "INFO" "HLQ: $HLQ"
    log_message "INFO" "Environment: $ENVIRONMENT"
    
    # Create directories if they don't exist
    mkdir -p "$LOG_DIR" "$OUTPUT_DIR"
    
    # Run validation checks
    validate_job_outputs
    validate_uss_files
    validate_permissions
    validate_workflow_status
    validate_system_resources
    
    # Generate final report
    generate_validation_report
    
    log_message "INFO" "=== Workflow Validation Completed ==="
    log_message "INFO" "Final Status: Errors=$VALIDATION_ERRORS, Warnings=$VALIDATION_WARNINGS"
    
    # Return appropriate exit code
    if [ $VALIDATION_ERRORS -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Execute main function
main "$@"