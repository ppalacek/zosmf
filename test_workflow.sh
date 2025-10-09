#!/bin/sh
#
# test_workflow.sh - Test workflow execution and validate results
#
# This script provides comprehensive testing for the zOSMF workflow including:
# - End-to-end workflow execution testing
# - Individual step testing
# - Result validation
# - Performance monitoring
# - Error handling validation
#
# Usage: ./test_workflow.sh [test_type] [work_dir] [environment]
#
# Parameters:
#   test_type   - Type of test (full|quick|step|validate|performance)
#   work_dir    - Working directory (default: /u/user/workflow)
#   environment - Target environment (DEV|TEST|PROD)
#

# Set default values
TEST_TYPE="${1:-quick}"
WORK_DIR="${2:-/u/$(whoami)/workflow}"
ENVIRONMENT="${3:-TEST}"

# Configuration
LOG_DIR="$WORK_DIR/logs"
OUTPUT_DIR="$WORK_DIR/output"
TEST_LOG="$LOG_DIR/test_execution_$(date '+%Y%m%d_%H%M%S').log"

# Test results tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNINGS=0

# Function to log messages with test context
log_test() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp [$level] $message" | tee -a "$TEST_LOG"
    
    case "$level" in
        "PASS")
            TESTS_PASSED=$((TESTS_PASSED + 1))
            ;;
        "FAIL")
            TESTS_FAILED=$((TESTS_FAILED + 1))
            ;;
        "WARN")
            TESTS_WARNINGS=$((TESTS_WARNINGS + 1))
            ;;
    esac
    
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Function to run a test with error handling
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    log_test "INFO" "Running test: $test_name"
    
    # Execute test command
    test_output=$(eval "$test_command" 2>&1)
    test_result=$?
    
    # Evaluate result
    if [ "$expected_result" = "0" ] && [ $test_result -eq 0 ]; then
        log_test "PASS" "$test_name - Command executed successfully"
        return 0
    elif [ "$expected_result" = "non-zero" ] && [ $test_result -ne 0 ]; then
        log_test "PASS" "$test_name - Command failed as expected"
        return 0
    elif [ "$expected_result" = "any" ]; then
        log_test "PASS" "$test_name - Command completed (result: $test_result)"
        return 0
    else
        log_test "FAIL" "$test_name - Unexpected result (expected: $expected_result, got: $test_result)"
        log_test "INFO" "Output: $test_output"
        return 1
    fi
}

# Function to test USS environment setup
test_uss_environment() {
    log_test "INFO" "=== Testing USS Environment ==="
    
    # Test directory structure
    directories="scripts jcl python logs output config backup temp"
    for dir in $directories; do
        if [ -d "$WORK_DIR/$dir" ]; then
            log_test "PASS" "Directory exists: $dir"
        else
            log_test "FAIL" "Directory missing: $dir"
        fi
    done
    
    # Test file permissions
    run_test "Scripts executable" "find '$WORK_DIR/scripts' -name '*.sh' -executable" "any"
    run_test "Python files readable" "find '$WORK_DIR/python' -name '*.py' -readable" "any"
    run_test "JCL files readable" "find '$WORK_DIR/jcl' -name '*.jcl' -readable" "any"
    
    # Test disk space
    available_space=$(df "$WORK_DIR" | tail -1 | awk '{print $4}')
    if [ "$available_space" -gt 50000 ]; then
        log_test "PASS" "Sufficient disk space available: $available_space KB"
    else
        log_test "WARN" "Low disk space: $available_space KB"
    fi
}

# Function to test configuration files
test_configuration() {
    log_test "INFO" "=== Testing Configuration Files ==="
    
    config_files="workflow.properties variables.properties environment.conf"
    for file in $config_files; do
        config_path="$WORK_DIR/config/$file"
        if [ -f "$config_path" ]; then
            log_test "PASS" "Configuration file exists: $file"
            
            # Test file format
            if grep -q "=" "$config_path"; then
                log_test "PASS" "Configuration file format valid: $file"
            else
                log_test "WARN" "Configuration file may have format issues: $file"
            fi
        else
            log_test "FAIL" "Configuration file missing: $file"
        fi
    done
    
    # Test workflow definition
    workflow_def="$WORK_DIR/workflow-definition.xml"
    if [ -f "$workflow_def" ]; then
        log_test "PASS" "Workflow definition exists"
        
        if grep -q "<?xml" "$workflow_def"; then
            log_test "PASS" "Workflow definition has valid XML header"
        else
            log_test "FAIL" "Workflow definition missing XML header"
        fi
        
        if grep -q "<workflow" "$workflow_def"; then
            log_test "PASS" "Workflow definition has workflow element"
        else
            log_test "FAIL" "Workflow definition missing workflow element"
        fi
    else
        log_test "FAIL" "Workflow definition missing: $workflow_def"
    fi
}

# Function to test JCL templates
test_jcl_templates() {
    log_test "INFO" "=== Testing JCL Templates ==="
    
    jcl_files="create_datasets.jcl process_data.jcl cleanup.jcl"
    for jcl in $jcl_files; do
        jcl_path="$WORK_DIR/jcl/$jcl"
        if [ -f "$jcl_path" ]; then
            log_test "PASS" "JCL template exists: $jcl"
            
            # Test JCL format
            if grep -q "^//" "$jcl_path"; then
                log_test "PASS" "JCL template has valid format: $jcl"
            else
                log_test "FAIL" "JCL template format invalid: $jcl"
            fi
            
            # Test parameter substitution variables
            if grep -q "&" "$jcl_path"; then
                log_test "PASS" "JCL template has parameter substitution: $jcl"
            else
                log_test "WARN" "JCL template may not use parameter substitution: $jcl"
            fi
        else
            log_test "FAIL" "JCL template missing: $jcl"
        fi
    done
}

# Function to test shell scripts
test_shell_scripts() {
    log_test "INFO" "=== Testing Shell Scripts ==="
    
    scripts="setup_dirs.sh run_python.sh validate_results.sh"
    for script in $scripts; do
        script_path="$WORK_DIR/scripts/$script"
        if [ -f "$script_path" ]; then
            log_test "PASS" "Shell script exists: $script"
            
            # Test script permissions
            if [ -x "$script_path" ]; then
                log_test "PASS" "Shell script is executable: $script"
            else
                log_test "FAIL" "Shell script is not executable: $script"
            fi
            
            # Test script syntax (basic)
            if sh -n "$script_path" 2>/dev/null; then
                log_test "PASS" "Shell script syntax valid: $script"
            else
                log_test "FAIL" "Shell script syntax error: $script"
            fi
        else
            log_test "FAIL" "Shell script missing: $script"
        fi
    done
    
    # Test script execution (safe scripts only)
    run_test "Setup directories validation" "'$WORK_DIR/scripts/validate_setup.sh' '$WORK_DIR'" "0"
}

# Function to test Python environment
test_python_environment() {
    log_test "INFO" "=== Testing Python Environment ==="
    
    # Test Python availability
    python_paths="/usr/lpp/IBM/cyp/v3r9/pyz/bin/python3 /usr/bin/python3 python3"
    python_found=false
    
    for python_path in $python_paths; do
        if command -v "$python_path" >/dev/null 2>&1; then
            log_test "PASS" "Python found: $python_path"
            python_found=true
            
            # Test Python version
            python_version=$($python_path --version 2>&1)
            log_test "INFO" "Python version: $python_version"
            break
        fi
    done
    
    if [ "$python_found" = false ]; then
        log_test "FAIL" "Python not found in expected locations"
    fi
    
    # Test Python scripts
    python_scripts="data_processor.py workflow_utilities.py"
    for script in $python_scripts; do
        script_path="$WORK_DIR/python/$script"
        if [ -f "$script_path" ]; then
            log_test "PASS" "Python script exists: $script"
            
            # Test Python syntax
            if python3 -m py_compile "$script_path" 2>/dev/null; then
                log_test "PASS" "Python script syntax valid: $script"
            else
                log_test "FAIL" "Python script syntax error: $script"
            fi
        else
            log_test "FAIL" "Python script missing: $script"
        fi
    done
}

# Function to test workflow step execution
test_workflow_steps() {
    log_test "INFO" "=== Testing Workflow Step Execution ==="
    
    # Test USS directory setup
    if [ -x "$WORK_DIR/scripts/setup_dirs.sh" ]; then
        run_test "USS directory setup" "'$WORK_DIR/scripts/setup_dirs.sh' '$WORK_DIR/test_temp'" "0"
        
        # Cleanup test directory
        rm -rf "$WORK_DIR/test_temp" 2>/dev/null
    fi
    
    # Test Python script execution (dry run)
    if [ -x "$WORK_DIR/scripts/run_python.sh" ]; then
        # Create a test Python script that doesn't require system resources
        test_python_script="$WORK_DIR/python/test_script.py"
        cat > "$test_python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import os
print("Test Python script executed successfully")
print(f"Arguments: {sys.argv}")
print(f"Working directory: {os.getcwd()}")
sys.exit(0)
EOF
        chmod 755 "$test_python_script"
        
        run_test "Python execution test" "'$WORK_DIR/scripts/run_python.sh' 'test_script.py' '$WORK_DIR' '$ENVIRONMENT'" "0"
        
        # Cleanup test script
        rm -f "$test_python_script" 2>/dev/null
    fi
    
    # Test result validation
    if [ -x "$WORK_DIR/scripts/validate_results.sh" ]; then
        run_test "Result validation test" "'$WORK_DIR/scripts/validate_results.sh' '$WORK_DIR' 'TESTUSER' '$ENVIRONMENT'" "any"
    fi
}

# Function to test error handling
test_error_handling() {
    log_test "INFO" "=== Testing Error Handling ==="
    
    # Test with invalid parameters
    run_test "Invalid directory handling" "'$WORK_DIR/scripts/setup_dirs.sh' '/invalid/directory/path'" "non-zero"
    
    # Test with missing files
    run_test "Missing file handling" "cat '$WORK_DIR/nonexistent_file.txt'" "non-zero"
    
    # Test permission errors (if we can create them safely)
    test_file="$WORK_DIR/temp/permission_test.txt"
    echo "test" > "$test_file" 2>/dev/null
    if [ -f "$test_file" ]; then
        chmod 000 "$test_file"
        run_test "Permission error handling" "cat '$test_file'" "non-zero"
        chmod 644 "$test_file"
        rm -f "$test_file"
    fi
}

# Function to test performance
test_performance() {
    log_test "INFO" "=== Testing Performance ==="
    
    # Test file I/O performance
    start_time=$(date +%s)
    test_data_file="$WORK_DIR/temp/performance_test.dat"
    
    # Create test data
    for i in $(seq 1 1000); do
        echo "Test data line $i" >> "$test_data_file"
    done
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    if [ $duration -lt 10 ]; then
        log_test "PASS" "File I/O performance acceptable: $duration seconds"
    else
        log_test "WARN" "File I/O performance slow: $duration seconds"
    fi
    
    # Test script execution time
    if [ -x "$WORK_DIR/scripts/validate_setup.sh" ]; then
        start_time=$(date +%s)
        "$WORK_DIR/scripts/validate_setup.sh" "$WORK_DIR" >/dev/null 2>&1
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        if [ $duration -lt 30 ]; then
            log_test "PASS" "Script execution performance acceptable: $duration seconds"
        else
            log_test "WARN" "Script execution performance slow: $duration seconds"
        fi
    fi
    
    # Cleanup performance test files
    rm -f "$test_data_file" 2>/dev/null
}

# Function to generate test report
generate_test_report() {
    log_test "INFO" "=== Generating Test Report ==="
    
    report_file="$OUTPUT_DIR/test_report_$(date '+%Y%m%d_%H%M%S').txt"
    
    {
        echo "========================================"
        echo "    WORKFLOW TESTING REPORT"
        echo "========================================"
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Test Type: $TEST_TYPE"
        echo "Work Directory: $WORK_DIR"
        echo "Environment: $ENVIRONMENT"
        echo ""
        echo "TEST SUMMARY:"
        echo "  Total Tests: $TESTS_RUN"
        echo "  Passed: $TESTS_PASSED"
        echo "  Failed: $TESTS_FAILED"
        echo "  Warnings: $TESTS_WARNINGS"
        echo ""
        
        if [ $TESTS_FAILED -eq 0 ]; then
            echo "OVERALL RESULT: PASSED"
            if [ $TESTS_WARNINGS -eq 0 ]; then
                echo "STATUS: All tests passed successfully"
            else
                echo "STATUS: Passed with $TESTS_WARNINGS warnings"
            fi
        else
            echo "OVERALL RESULT: FAILED"
            echo "STATUS: $TESTS_FAILED tests failed"
        fi
        
        echo ""
        echo "DETAILED LOG:"
        echo "See $TEST_LOG for complete details"
        echo ""
        echo "NEXT STEPS:"
        if [ $TESTS_FAILED -eq 0 ]; then
            echo "- Workflow is ready for registration with zOSMF"
            echo "- Run './register_workflow.sh' to register with zOSMF"
            echo "- Create workflow instance in zOSMF interface"
        else
            echo "- Review failed tests in detailed log"
            echo "- Fix issues before proceeding"
            echo "- Re-run tests after fixes"
        fi
        echo ""
        echo "========================================"
        echo "    END OF TEST REPORT"
        echo "========================================"
    } > "$report_file"
    
    log_test "INFO" "Test report created: $report_file"
    
    # Display report summary
    cat "$report_file"
}

# Main testing function
main() {
    log_test "INFO" "=== Starting Workflow Testing ==="
    log_test "INFO" "Test Type: $TEST_TYPE"
    log_test "INFO" "Work Directory: $WORK_DIR"
    log_test "INFO" "Environment: $ENVIRONMENT"
    log_test "INFO" "Test Log: $TEST_LOG"
    
    # Create directories if needed
    mkdir -p "$LOG_DIR" "$OUTPUT_DIR" "$WORK_DIR/temp"
    
    # Run tests based on test type
    case "$TEST_TYPE" in
        "full")
            test_uss_environment
            test_configuration
            test_jcl_templates
            test_shell_scripts
            test_python_environment
            test_workflow_steps
            test_error_handling
            test_performance
            ;;
        "quick")
            test_uss_environment
            test_configuration
            test_shell_scripts
            ;;
        "step")
            test_workflow_steps
            ;;
        "validate")
            test_configuration
            test_jcl_templates
            ;;
        "performance")
            test_performance
            ;;
        *)
            log_test "ERROR" "Unknown test type: $TEST_TYPE"
            echo "Valid test types: full, quick, step, validate, performance"
            exit 1
            ;;
    esac
    
    # Generate test report
    generate_test_report
    
    log_test "INFO" "=== Testing Completed ==="
    log_test "INFO" "Final Status: Run=$TESTS_RUN, Passed=$TESTS_PASSED, Failed=$TESTS_FAILED, Warnings=$TESTS_WARNINGS"
    
    # Return appropriate exit code
    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Execute main function
main "$@"