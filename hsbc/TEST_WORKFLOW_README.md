# Simple Test Workflow - Quick Reference Guide

## Files Created

1. **test-workflow-v1.0.xml** - Main workflow definition file
2. **test-workflow-defaults-v1.0.properties** - Default property values
3. **SUBMIT_TEST_WORKFLOW.jcl** - JCL to submit workflow via REST API

## Workflow Steps

The test workflow includes 5 steps:

1. **Delete-Test-ZFS** - Deletes existing test ZFS if present
2. **Allocate-Test-ZFS** - Creates new 100MB ZFS dataset
3. **Mount-Test-ZFS** - Mounts ZFS to /tmp/testWorkflow
4. **Create-Test-File** - Creates timestamped test file
5. **Unmount-Test-ZFS** - Unmounts the ZFS filesystem

## Dataset Naming

Following the DB2 V13 workflow convention:
- **Dataset**: `SYSD.SHOPZ.{MAINT_LVL}.TEST.ZFS`
- **Default**: `SYSD.SHOPZ.PC5V620.TEST.ZFS`

## How to Use

### Option 1: Via z/OSMF Web UI (Recommended)

1. Upload files to USS:
   ```
   /u/d33553/workflows/test-workflow-v1.0.xml
   /u/d33553/workflows/test-workflow-defaults-v1.0.properties
   ```

2. In z/OSMF:
   - Navigate to **Workflows**
   - Click **Create Workflow**
   - Select the XML file
   - Select the properties file
   - Click **Create**

3. Execute the workflow step by step or all at once

### Option 2: Via REST API (Using JCL)

1. Upload workflow files to USS (as above)

2. Edit `SUBMIT_TEST_WORKFLOW.jcl`:
   - Replace `your-zosmf-host` with actual hostname
   - Replace `yourpassword` with your password
   - Replace `your-system-name` with your system name
   - Adjust USS paths if different

3. Submit the JCL from SDSF:
   ```
   =sd;sub
   ```

4. Note the workflow key from the output

5. Access workflow in z/OSMF UI using the workflow key

### Option 3: Manual JCL Submission

Instead of using z/OSMF, you can submit each step manually:

1. Copy the JCL from each step in the XML file
2. Submit individually through SDSF or TSO
3. Verify each step completes successfully

## Configuration Variables

Edit `test-workflow-defaults-v1.0.properties` to customize:

- **MAINT_LVL**: Maintenance level (default: PC5V620)
- **USER_ID**: Your TSO user ID (default: D33553)
- **TEST_MOUNT_POINT**: Mount point (default: /tmp/testWorkflow)

## Verification

After execution:

1. Check dataset exists:
   ```
   LISTDS 'SYSD.SHOPZ.PC5V620.TEST.ZFS'
   ```

2. Mount and verify file:
   ```
   MOUNT FILESYSTEM('SYSD.SHOPZ.PC5V620.TEST.ZFS') +
         MOUNTPOINT('/tmp/testWorkflow') +
         TYPE(ZFS) MODE(RDWR)
   
   cat /tmp/testWorkflow/test_file.txt
   ```

3. Unmount when done:
   ```
   UNMOUNT FILESYSTEM('SYSD.SHOPZ.PC5V620.TEST.ZFS')
   ```

## Cleanup

To remove the test ZFS:

```jcl
//DELETE   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE SYSD.SHOPZ.PC5V620.TEST.ZFS PURGE
/*
```

## Troubleshooting

### Mount Point Already In Use
If `/tmp/testWorkflow` is already mounted, unmount first or change `TEST_MOUNT_POINT` in properties.

### Dataset Already Exists
Step 1 (Delete-Test-ZFS) should handle this automatically.

### Insufficient Authority
Ensure you have:
- RACF authority to allocate in SYSD HLQ
- Mount authority for filesystems
- z/OSMF workflow creation authority

### z/OSMF REST API Issues
- Verify z/OSMF server is running
- Check network connectivity
- Verify credentials
- Check SSL/TLS certificate trust

## Next Steps

This workflow is designed for:
- Testing z/OSMF workflow functionality
- Learning workflow structure and steps
- Planning more complex workflows
- Demonstrating workflow capabilities

Use it as a template for creating more sophisticated workflows!
