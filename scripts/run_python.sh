#!/bin/sh
#
# run_python.sh - Execute Python processing for workflow
#
# This script demonstrates Python integration with zOS workflows
# It can call Python scripts for data processing, analysis, and automation
#
# Usage: ./run_python.sh [script_name] [work_dir] [environment]
#
# Parameters:
#   script_name - Python script to execute (default: data_processor.py)
#   work_dir    - Working directory (default: current user's home/workflow)
#   environment - Target environment (DEV/TEST/PROD)
#

# Set default values
SCRIPT_NAME="${1:-data_processor.py}"
WORK_DIR="${2:-/u/$(whoami)/workflow}"
ENVIRONMENT="${3:-TEST}"

# Configuration
PYTHON_DIR="$WORK_DIR/python"
LOG_DIR="$WORK_DIR/logs"
OUTPUT_DIR="$WORK_DIR/output"
CONFIG_DIR="$WORK_DIR/config"

# Python paths - adjust for your system
PYTHON_HOME="/usr/lpp/IBM/cyp/v3r9/pyz"
PYTHON_BIN="$PYTHON_HOME/bin/python3"
PYTHON_LIB="$PYTHON_HOME/lib"

# Function to log messages
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $1" | tee -a "$LOG_DIR/python_execution.log"
}

# Function to check if Python is available
check_python() {
    log_message "Checking Python availability..."
    
    if [ -x "$PYTHON_BIN" ]; then
        log_message "Python found at: $PYTHON_BIN"
        PYTHON_VERSION=$($PYTHON_BIN --version 2>&1)
        log_message "Python version: $PYTHON_VERSION"
        return 0
    else
        log_message "ERROR: Python not found at $PYTHON_BIN"
        log_message "Please verify Python installation and update PYTHON_BIN variable"
        return 1
    fi
}

# Function to set Python environment
setup_python_env() {
    log_message "Setting up Python environment..."
    
    # Set Python path
    export PYTHONPATH="$PYTHON_LIB:$PYTHON_DIR:$PYTHON_DIR/modules:$PYTHON_DIR/site-packages"
    
    # Set library path
    export LIBPATH="$PYTHON_LIB:$LIBPATH"
    
    # Set other environment variables
    export PYTHON_HOME="$PYTHON_HOME"
    export WORKFLOW_HOME="$WORK_DIR"
    export WORKFLOW_ENVIRONMENT="$ENVIRONMENT"
    export WORKFLOW_LOG_DIR="$LOG_DIR"
    export WORKFLOW_OUTPUT_DIR="$OUTPUT_DIR"
    
    log_message "Python environment configured:"
    log_message "  PYTHONPATH: $PYTHONPATH"
    log_message "  LIBPATH: $LIBPATH"
    log_message "  WORKFLOW_HOME: $WORKFLOW_HOME"
    log_message "  WORKFLOW_ENVIRONMENT: $WORKFLOW_ENVIRONMENT"
}

# Function to execute Python script
execute_python_script() {
    local script_path="$PYTHON_DIR/$SCRIPT_NAME"
    local output_file="$OUTPUT_DIR/python_output_$(date '+%Y%m%d_%H%M%S').txt"
    local error_file="$LOG_DIR/python_error_$(date '+%Y%m%d_%H%M%S').txt"
    
    log_message "Executing Python script: $SCRIPT_NAME"
    log_message "Script path: $script_path"
    log_message "Output file: $output_file"
    log_message "Error file: $error_file"
    
    if [ ! -f "$script_path" ]; then
        log_message "ERROR: Python script not found: $script_path"
        return 1
    fi
    
    # Execute the Python script
    log_message "Starting Python script execution..."
    
    $PYTHON_BIN "$script_path" \
        --work-dir "$WORK_DIR" \
        --environment "$ENVIRONMENT" \
        --log-dir "$LOG_DIR" \
        --output-dir "$OUTPUT_DIR" \
        > "$output_file" 2> "$error_file"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_message "Python script completed successfully (exit code: $exit_code)"
        log_message "Output written to: $output_file"
        
        # Display summary of output
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            log_message "Output summary:"
            head -20 "$output_file" | while read line; do
                log_message "  $line"
            done
        fi
    else
        log_message "ERROR: Python script failed (exit code: $exit_code)"
        log_message "Error details written to: $error_file"
        
        # Display error information
        if [ -f "$error_file" ] && [ -s "$error_file" ]; then
            log_message "Error details:"
            head -20 "$error_file" | while read line; do
                log_message "  ERROR: $line"
            done
        fi
        return $exit_code
    fi
}

# Function to process results
process_results() {
    log_message "Processing Python execution results..."
    
    # Count output files
    output_count=$(find "$OUTPUT_DIR" -name "python_output_*.txt" -type f | wc -l)
    log_message "Total Python output files: $output_count"
    
    # Check for errors
    error_count=$(find "$LOG_DIR" -name "python_error_*.txt" -type f -size +0 | wc -l)
    if [ $error_count -gt 0 ]; then
        log_message "Warning: $error_count error files found"
    else
        log_message "No error files with content found"
    fi
    
    # Generate summary report
    summary_file="$OUTPUT_DIR/python_execution_summary.txt"
    {
        echo "=== Python Execution Summary ==="
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Script: $SCRIPT_NAME"
        echo "Work Directory: $WORK_DIR"
        echo "Environment: $ENVIRONMENT"
        echo "Output Files: $output_count"
        echo "Error Files: $error_count"
        echo ""
        echo "=== Environment Variables ==="
        echo "PYTHONPATH: $PYTHONPATH"
        echo "PYTHON_HOME: $PYTHON_HOME"
        echo "WORKFLOW_HOME: $WORKFLOW_HOME"
        echo ""
        echo "=== File Locations ==="
        echo "Script Directory: $PYTHON_DIR"
        echo "Log Directory: $LOG_DIR"
        echo "Output Directory: $OUTPUT_DIR"
        echo ""
        echo "=== Latest Output Files ==="
        find "$OUTPUT_DIR" -name "python_output_*.txt" -type f -exec ls -la {} \;
        echo ""
        echo "=== Summary Complete ==="
    } > "$summary_file"
    
    log_message "Summary report created: $summary_file"
}

# Main execution
main() {
    log_message "=== Starting Python execution script ==="
    log_message "Script: $SCRIPT_NAME"
    log_message "Work Directory: $WORK_DIR"
    log_message "Environment: $ENVIRONMENT"
    
    # Create directories if they don't exist
    mkdir -p "$LOG_DIR" "$OUTPUT_DIR" "$PYTHON_DIR"
    
    # Check Python availability
    if ! check_python; then
        exit 1
    fi
    
    # Setup Python environment
    setup_python_env
    
    # Execute Python script
    if execute_python_script; then
        log_message "Python script execution completed successfully"
    else
        log_message "Python script execution failed"
        exit 1
    fi
    
    # Process results
    process_results
    
    log_message "=== Python execution script completed ==="
}

# Execute main function
main "$@"

exit 0