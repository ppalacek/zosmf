# zOSMF Workflow Baseline Testing Framework

## Overview

This framework provides a comprehensive baseline structure for testing zOS workflows with parameters, USS, JCL, and Python integration. It's designed to work in environments where VS Code cannot be run on the target system, allowing you to develop locally and deploy to the target z/OS environment.

## Features

- **Complete workflow definition** with parameter handling and variable substitution
- **Multi-step JCL execution** with conditional logic based on environment
- **USS script integration** for file operations and environment setup
- **Python script execution** for data processing and automation
- **Comprehensive testing framework** with validation and error handling
- **Easy deployment scripts** for target system installation
- **zOSMF registration utilities** for workflow registration

## Directory Structure

```
ZOSMF/
├── workflow-definition.xml          # Main workflow definition
├── workflow.properties              # Workflow configuration
├── variables.properties             # Variable definitions
├── install_workflow.sh             # Installation script
├── register_workflow.sh             # zOSMF registration script
├── test_workflow.sh                # Testing framework
├── jcl/                           # JCL templates
│   ├── create_datasets.jcl         # Dataset creation job
│   ├── process_data.jcl            # Data processing job
│   └── cleanup.jcl                 # Cleanup job
├── scripts/                       # USS shell scripts
│   ├── setup_dirs.sh               # Directory setup
│   ├── run_python.sh               # Python execution wrapper
│   └── validate_results.sh         # Result validation
└── python/                        # Python scripts
    ├── data_processor.py           # Main data processing
    └── workflow_utilities.py       # Utility functions
```

## Quick Start Guide

### 1. Local Development Setup

1. Clone or download this framework to your local development environment
2. Review and customize the workflow definition in `workflow-definition.xml`
3. Modify configuration files to match your environment requirements
4. Test the framework locally using the provided test scripts

### 2. Target System Deployment

1. **Upload files to target system:**
   ```bash
   # If you have direct access to the target system
   ./install_workflow.sh your_userid target_system /u/your_userid/workflow
   
   # Or manually upload files via FTP/SFTP to USS
   ```

2. **Set up the environment:**
   ```bash
   # On the target system
   cd /u/your_userid/workflow
   ./scripts/setup_dirs.sh
   ```

3. **Test the installation:**
   ```bash
   ./test_workflow.sh quick /u/your_userid/workflow TEST
   ```

### 3. zOSMF Registration

1. **Register workflow with zOSMF:**
   ```bash
   ./register_workflow.sh zosmf_host 443 your_userid /u/your_userid/workflow
   ```

2. **Access zOSMF interface:**
   - Open web browser to `https://zosmf_host:443/zosmf`
   - Navigate to Workflows
   - Find your registered workflow: `BASELINE_WORKFLOW_TEST`

### 4. Workflow Execution

1. **Create workflow instance** in zOSMF interface
2. **Configure parameters:**
   - `WORKFLOW_OWNER`: Your TSO user ID
   - `JOB_PREFIX`: Job name prefix (3-4 characters)
   - `HLQ`: Dataset high level qualifier
   - `USS_WORK_DIR`: `/u/your_userid/workflow`
   - `ENVIRONMENT`: DEV/TEST/PROD
   - `PYTHON_ENABLED`: true/false
3. **Execute workflow steps** in sequence

## Detailed Documentation

### Workflow Parameters

| Parameter | Description | Type | Default | Required |
|-----------|-------------|------|---------|----------|
| WORKFLOW_OWNER | TSO user ID for job submission | String | ${instance-owner} | Yes |
| JOB_PREFIX | Prefix for all submitted jobs | String | TEST | Yes |
| HLQ | Dataset high level qualifier | String | ${instance-WORKFLOW_OWNER} | Yes |
| USS_WORK_DIR | USS working directory path | String | /u/${instance-WORKFLOW_OWNER}/workflow | Yes |
| ENVIRONMENT | Target environment | Choice | TEST | Yes |
| PYTHON_ENABLED | Enable Python processing | Boolean | true | No |

### Workflow Steps

#### Step 1: Initialize Environment
- **Step 1a**: Validate input parameters
- **Step 1b**: Setup USS environment
  - **Step 1b1**: Create USS directories

#### Step 2: Execute JCL Jobs
- **Step 2a**: Submit dataset creation job
- **Step 2b**: Submit data processing job

#### Step 3: Execute Python Processing (Optional)
- **Step 3a**: Run Python data analysis

#### Step 4: Cleanup and Validation
- **Step 4a**: Validate results
- **Step 4b**: Cleanup temporary resources (Optional)

### JCL Templates

#### create_datasets.jcl
Creates required datasets for workflow processing:
- Work dataset (`&HLQ..WORK.DATA`)
- Temporary processing dataset (`&HLQ..TEMP.PROCESS`)
- Log dataset (`&HLQ..LOG.&ENVIRONMENT`)
- Control dataset (`&HLQ..CONTROL.CARDS`)
- Backup dataset (`&HLQ..BACKUP.&ENVIRONMENT`)

Features:
- Parameter substitution for all variables
- Conditional processing based on environment
- Error handling and logging

#### process_data.jcl
Demonstrates complex data processing:
- Data validation and sorting
- Environment-specific processing logic
- Conditional JCL execution
- Multi-step processing with dependencies

#### cleanup.jcl
Handles cleanup and final reporting:
- Final report generation
- Log file archiving
- Dataset cleanup based on environment
- Status updates

### USS Shell Scripts

#### setup_dirs.sh
Creates and configures USS directory structure:
- Creates all required directories
- Sets appropriate permissions
- Creates initial configuration files
- Provides validation capabilities

#### run_python.sh
Python execution wrapper:
- Manages Python environment setup
- Handles parameter passing
- Provides logging and error handling
- Supports multiple Python versions

#### validate_results.sh
Comprehensive result validation:
- Validates job outputs
- Checks USS file structure
- Verifies permissions
- Generates validation reports

### Python Scripts

#### data_processor.py
Main data processing script featuring:
- Dataset analysis and processing
- Environment-specific logic
- Configuration management
- Comprehensive logging
- Report generation

#### workflow_utilities.py
Utility module providing:
- Dataset operation utilities
- USS file manipulation
- Configuration management
- System integration helpers
- Error handling utilities

### Configuration Files

#### workflow.properties
Main workflow configuration:
- Default parameter values
- System configuration
- Environment-specific settings
- Performance tuning options

#### variables.properties
Variable definitions and validation:
- Parameter validation rules
- Data type definitions
- Default values
- Environment mappings

## Testing Framework

### Test Types

- **quick**: Basic environment and configuration tests
- **full**: Comprehensive testing including performance
- **step**: Individual workflow step testing
- **validate**: Configuration and template validation
- **performance**: Performance and load testing

### Running Tests

```bash
# Quick test
./test_workflow.sh quick /u/userid/workflow TEST

# Full comprehensive test
./test_workflow.sh full /u/userid/workflow TEST

# Validate configuration only
./test_workflow.sh validate /u/userid/workflow TEST
```

### Test Coverage

- USS environment setup
- Configuration file validation
- JCL template syntax and logic
- Shell script execution
- Python environment and scripts
- Error handling and recovery
- Performance benchmarks

## Environment-Specific Behavior

### Development (DEV)
- Minimal validation
- Extended debugging
- Temporary dataset cleanup
- Development-specific logging

### Test (TEST)
- Standard validation
- Performance monitoring
- Partial dataset retention
- Test-specific processing

### Production (PROD)
- Full validation and auditing
- Multiple backup copies
- Extended dataset retention
- Production-specific security

## Troubleshooting

### Common Issues

1. **Permission Errors**
   - Verify USS directory permissions
   - Check TSO user access rights
   - Validate dataset access permissions

2. **Python Execution Failures**
   - Verify Python installation path
   - Check PYTHONPATH configuration
   - Validate Python script syntax

3. **JCL Submission Errors**
   - Check job class availability
   - Verify dataset naming conventions
   - Validate JCL syntax

4. **Workflow Registration Issues**
   - Verify zOSMF connectivity
   - Check authentication credentials
   - Validate workflow definition XML

### Debug Tools

1. **Validation Script**: `./scripts/validate_setup.sh`
2. **Test Framework**: `./test_workflow.sh`
3. **Log Analysis**: Check files in `logs/` directory
4. **Manual Testing**: Execute individual scripts

### Log Files

- `logs/setup.log`: Environment setup log
- `logs/validation.log`: Validation results
- `logs/test_execution_*.log`: Test execution logs
- `logs/python_processor_*.log`: Python execution logs

## Best Practices

### Development
- Test locally before deployment
- Use version control for workflow definitions
- Document parameter changes
- Validate all templates before deployment

### Deployment
- Use consistent naming conventions
- Backup existing workflows before updates
- Test in DEV environment first
- Document deployment procedures

### Operations
- Monitor workflow execution logs
- Implement proper error handling
- Use environment-specific configurations
- Maintain backup and recovery procedures

## Advanced Features

### Custom Step Development
1. Define new steps in workflow-definition.xml
2. Create corresponding JCL or script templates
3. Add parameter validation
4. Update test framework

### Integration with External Systems
- REST API calls from Python scripts
- Database connectivity
- File transfer operations
- Email notifications

### Security Considerations
- Use proper dataset protection
- Implement access controls
- Secure credential management
- Audit trail maintenance

## Support and Maintenance

### Regular Maintenance
- Update Python dependencies
- Refresh JCL templates
- Review and update documentation
- Performance optimization

### Monitoring
- Workflow execution metrics
- Resource utilization
- Error rate tracking
- Performance benchmarks

### Updates
- Test all changes in non-production environments
- Maintain backward compatibility
- Document all modifications
- Provide migration guides

## Conclusion

This framework provides a solid foundation for zOS workflow development and testing. It demonstrates best practices for multi-technology integration and provides comprehensive tools for deployment and maintenance in z/OS environments.

For additional support or customization, refer to the individual script documentation and IBM zOSMF documentation.