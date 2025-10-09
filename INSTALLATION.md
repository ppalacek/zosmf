# Installation and Setup Guide

## Prerequisites

### System Requirements
- z/OS system with zOSMF installed and configured
- USS (Unix System Services) access
- TSO user ID with appropriate permissions
- Python 3.x installed (optional, for Python features)

### Required Permissions
- READ/WRITE access to USS directories
- Dataset creation and management permissions
- Job submission rights
- zOSMF workflow management access

### Network Requirements
- HTTPS access to zOSMF (typically port 443)
- SSH/SFTP access for file transfer (if deploying remotely)

## Installation Steps

### Step 1: Prepare Local Environment

1. **Download or clone the framework**
   ```bash
   # Clone from repository (if applicable)
   git clone <repository-url> zosmf-workflow
   cd zosmf-workflow
   ```

2. **Review and customize configuration**
   - Edit `workflow.properties` for your environment
   - Modify `variables.properties` as needed
   - Review JCL templates in `jcl/` directory
   - Customize Python scripts if needed

### Step 2: Deploy to Target System

#### Option A: Direct Installation (Local System)
```bash
# Install on local z/OS system
./install_workflow.sh $(whoami) localhost /u/$(whoami)/workflow
```

#### Option B: Remote Installation
```bash
# Install on remote z/OS system
./install_workflow.sh userid target_system /u/userid/workflow
```

#### Option C: Manual Upload
1. Create target directory structure:
   ```bash
   mkdir -p /u/userid/workflow/{scripts,jcl,python,logs,output,config,backup,temp}
   ```

2. Upload files via FTP/SFTP:
   ```bash
   # Upload main files
   sftp userid@target_system
   put workflow-definition.xml /u/userid/workflow/
   put workflow.properties /u/userid/workflow/config/
   put variables.properties /u/userid/workflow/config/
   
   # Upload directories
   put -r jcl/* /u/userid/workflow/jcl/
   put -r scripts/* /u/userid/workflow/scripts/
   put -r python/* /u/userid/workflow/python/
   ```

3. Set permissions:
   ```bash
   # On target system
   find /u/userid/workflow -name "*.sh" -exec chmod 755 {} \;
   find /u/userid/workflow -name "*.py" -exec chmod 755 {} \;
   chmod 644 /u/userid/workflow/jcl/*.jcl
   chmod 644 /u/userid/workflow/*.xml
   chmod 644 /u/userid/workflow/config/*.properties
   ```

### Step 3: Configure Environment

1. **Run environment setup**
   ```bash
   cd /u/userid/workflow
   ./scripts/setup_dirs.sh
   ```

2. **Verify installation**
   ```bash
   ./scripts/validate_setup.sh /u/userid/workflow
   ```

3. **Run basic tests**
   ```bash
   ./test_workflow.sh quick /u/userid/workflow TEST
   ```

### Step 4: Register with zOSMF

1. **Automatic registration**
   ```bash
   ./register_workflow.sh zosmf_host 443 userid /u/userid/workflow
   ```

2. **Manual registration via zOSMF interface**
   - Access zOSMF web interface
   - Navigate to Workflows → Register Workflow
   - Specify workflow definition file: `/u/userid/workflow/workflow-definition.xml`
   - Set appropriate properties

## Configuration Details

### Environment Configuration

Edit `/u/userid/workflow/config/environment.conf`:
```bash
# Environment Configuration
WORKFLOW_VERSION=1.0.0
WORKFLOW_HOME=/u/userid/workflow
WORKFLOW_OWNER=userid

# Python Configuration (if using Python features)
PYTHON_PATH=/usr/lpp/IBM/cyp/v3r9/pyz/bin/python3
PYTHON_HOME=/usr/lpp/IBM/cyp/v3r9/pyz

# System Configuration
JOB_CLASS=A
MSGCLASS=H
```

### Workflow Properties

Edit `/u/userid/workflow/config/workflow.properties`:
```properties
# Default Variable Values
default.WORKFLOW_OWNER=userid
default.JOB_PREFIX=TEST
default.HLQ=userid
default.USS_WORK_DIR=/u/userid/workflow
default.ENVIRONMENT=TEST
default.PYTHON_ENABLED=true

# System Configuration
system.max_concurrent_jobs=5
system.job_timeout=3600
system.default_job_class=A
system.default_msgclass=H
```

### Variable Definitions

Edit `/u/userid/workflow/config/variables.properties`:
```properties
# Variable validation rules
variable.WORKFLOW_OWNER.pattern=[A-Z][A-Z0-9]{0,7}
variable.JOB_PREFIX.pattern=[A-Z][A-Z0-9]{2,3}
variable.HLQ.pattern=[A-Z][A-Z0-9]{0,7}
variable.USS_WORK_DIR.pattern=/.*
```

## Validation and Testing

### Quick Validation
```bash
# Basic environment check
./scripts/validate_setup.sh /u/userid/workflow

# Quick test suite
./test_workflow.sh quick /u/userid/workflow TEST
```

### Comprehensive Testing
```bash
# Full test suite
./test_workflow.sh full /u/userid/workflow TEST

# Individual component tests
./test_workflow.sh validate /u/userid/workflow TEST
./test_workflow.sh performance /u/userid/workflow TEST
```

### Manual Verification

1. **Check directory structure**
   ```bash
   ls -la /u/userid/workflow
   # Should show: scripts, jcl, python, logs, output, config, backup, temp
   ```

2. **Verify file permissions**
   ```bash
   ls -la /u/userid/workflow/scripts/*.sh
   # Should show executable permissions (755)
   ```

3. **Test individual scripts**
   ```bash
   # Test directory setup
   ./scripts/setup_dirs.sh /tmp/test_workflow
   
   # Test result validation
   ./scripts/validate_results.sh /u/userid/workflow userid TEST
   ```

## Workflow Registration Verification

### Check Registration Status
1. Access zOSMF web interface
2. Navigate to Workflows
3. Look for workflow: `BASELINE_WORKFLOW_TEST`
4. Verify status and properties

### Test Workflow Instance Creation
1. Create new workflow instance
2. Set required parameters:
   - WORKFLOW_OWNER: userid
   - JOB_PREFIX: TEST
   - HLQ: userid
   - USS_WORK_DIR: /u/userid/workflow
   - ENVIRONMENT: TEST
3. Verify instance creation succeeds

## Troubleshooting Installation

### Common Issues and Solutions

#### Permission Denied Errors
```bash
# Fix script permissions
chmod 755 /u/userid/workflow/scripts/*.sh
chmod 755 /u/userid/workflow/python/*.py

# Fix directory permissions
chmod 755 /u/userid/workflow/*
```

#### zOSMF Registration Failures
1. **Check connectivity**
   ```bash
   curl -k https://zosmf_host:443/zosmf/info
   ```

2. **Verify credentials**
   - Ensure user has zOSMF access
   - Check password accuracy
   - Verify user permissions

3. **Check workflow definition**
   ```bash
   # Validate XML syntax
   xmllint --noout /u/userid/workflow/workflow-definition.xml
   ```

#### Python Execution Issues
1. **Check Python installation**
   ```bash
   /usr/lpp/IBM/cyp/v3r9/pyz/bin/python3 --version
   ```

2. **Verify Python path**
   ```bash
   which python3
   echo $PYTHONPATH
   ```

3. **Test Python scripts**
   ```bash
   python3 /u/userid/workflow/python/workflow_utilities.py
   ```

#### JCL Template Issues
1. **Check JCL syntax**
   ```bash
   # Review JCL for syntax errors
   cat /u/userid/workflow/jcl/create_datasets.jcl
   ```

2. **Verify parameter substitution**
   - Check for proper variable names (&VARIABLE format)
   - Ensure all required parameters are defined

#### Disk Space Issues
```bash
# Check available space
df /u/userid/workflow

# Clean up temporary files
rm -rf /u/userid/workflow/temp/*
rm -f /u/userid/workflow/logs/*.log.old
```

### Log Analysis

#### Installation Logs
- Check terminal output from installation script
- Review `/u/userid/workflow/logs/setup.log`

#### Test Logs
- Check test execution logs in `logs/test_execution_*.log`
- Review validation logs in `logs/validation.log`

#### Workflow Execution Logs
- Monitor zOSMF workflow execution logs
- Check individual step outputs
- Review job outputs in SDSF or equivalent

### Getting Help

#### Built-in Help
```bash
# Script usage information
./install_workflow.sh --help
./register_workflow.sh --help
./test_workflow.sh --help
```

#### Debug Mode
```bash
# Enable debug output
export DEBUG=true
./install_workflow.sh userid target_system /u/userid/workflow
```

#### Validation Tools
```bash
# Comprehensive validation
./scripts/validate_setup.sh /u/userid/workflow

# System prerequisites check
./python/workflow_utilities.py
```

## Post-Installation Steps

### 1. Create First Workflow Instance
1. Access zOSMF workflows interface
2. Create instance of `BASELINE_WORKFLOW_TEST`
3. Configure parameters for your environment
4. Execute workflow steps in sequence

### 2. Monitor Execution
- Check step completion status
- Review job outputs
- Monitor USS file creation
- Verify Python script execution (if enabled)

### 3. Customize for Your Needs
- Modify JCL templates for your processing requirements
- Enhance Python scripts for your data processing needs
- Add custom workflow steps as required
- Update configuration for your environment standards

### 4. Establish Maintenance Procedures
- Schedule regular testing
- Monitor disk space usage
- Update documentation as needed
- Plan for version updates

## Next Steps

After successful installation:

1. **Review the main README.md** for comprehensive usage information
2. **Explore the test framework** to understand validation capabilities
3. **Customize the workflow** for your specific requirements
4. **Set up monitoring and alerting** for production use
5. **Train users** on workflow execution procedures

## Support

For additional support:
- Review individual script documentation
- Check IBM zOSMF documentation
- Consult z/OS system administration guides
- Contact your system administrator for environment-specific issues