//D33553J  JOB (ACCTINFO),CLASS=A,MSGCLASS=X,
//         MSGLEVEL=(1,1),REGION=0M,NOTIFY=D33553
//********************************************************************
//* SUBMIT TEST WORKFLOW TO z/OSMF FROM SDSF
//********************************************************************
//*
//* This JCL creates and starts a z/OSMF workflow instance for the
//* Simple Test Workflow.
//*
//* INSTRUCTIONS:
//* 1. Update the workflow definition file location if needed
//* 2. Update the properties file location if needed
//* 3. Submit this JCL from SDSF (or TSO SUBMIT command)
//* 4. Review output for the workflow key
//* 5. Access workflow in z/OSMF UI using the workflow key
//*
//* PREREQUISITES:
//* - Workflow XML must be uploaded to USS location
//* - Properties file must be uploaded to USS location
//* - User must have authority to create z/OSMF workflows
//* - z/OSMF server must be active and accessible
//*
//********************************************************************
//*
//* STEP 1: CREATE WORKFLOW INSTANCE
//*
//********************************************************************
//CREATE   EXEC PGM=IKJEFT01,REGION=0M
//SYSTSPRT DD SYSOUT=*
//SYSTSIN  DD *
  BPXBATCH SH curl -k -X POST +
  https://your-zosmf-host:443/zosmf/workflow/rest/1.0/workflows +
  -H "Content-Type: application/json" +
  -H "X-CSRF-ZOSMF-HEADER: true" +
  -u "D33553:yourpassword" +
  -d '{
    "workflowName": "Test-Workflow-$(date +%Y%m%d-%H%M%S)",
    "workflowDefinitionFile": "/u/d33553/workflows/test-workflow-v1.0.xml",
    "variableInputFile": "/u/d33553/workflows/test-workflow-defaults-v1.0.properties",
    "system": "your-system-name",
    "owner": "D33553",
    "assignToOwner": true,
    "accessType": "Public",
    "accountInfo": "ACCTINFO",
    "jobStatement": "//D33553J JOB (ACCTINFO),CLASS=A,MSGCLASS=X,\n//         MSGLEVEL=(1,1),REGION=0M,NOTIFY=D33553"
  }' 2>&1 | tee /tmp/workflow_create_response.txt; +
  echo ""; +
  echo "Workflow creation response saved to /tmp/workflow_create_response.txt"; +
  echo "Extract the workflowKey from the response to access in z/OSMF"
/*
//*
//********************************************************************
//*
//* ALTERNATIVE: UPLOAD FILES TO USS FIRST (IF NOT ALREADY UPLOADED)
//*
//********************************************************************
//* Uncomment the steps below if you need to upload the workflow files
//* from z/OS datasets to USS before creating the workflow
//*
//*MKDIR    EXEC PGM=IKJEFT01,REGION=0M
//*SYSTSPRT DD SYSOUT=*
//*SYSTSIN  DD *
//*  BPXBATCH SH +
//*  mkdir -p /u/d33553/workflows; +
//*  chmod 755 /u/d33553/workflows
//*
//*CPXML    EXEC PGM=IKJEFT01,REGION=0M
//*SYSTSPRT DD SYSOUT=*
//*SYSTSIN  DD *
//*  OPUT 'YOUR.WORKFLOW.XML.DATASET' +
//*  '/u/d33553/workflows/test-workflow-v1.0.xml' TEXT
//*
//*CPPROP   EXEC PGM=IKJEFT01,REGION=0M
//*SYSTSPRT DD SYSOUT=*
//*SYSTSIN  DD *
//*  OPUT 'YOUR.WORKFLOW.PROPS.DATASET' +
//*  '/u/d33553/workflows/test-workflow-defaults-v1.0.properties' TEXT
//*
//********************************************************************
//*
//* NOTES:
//*
//* 1. Replace "your-zosmf-host" with actual z/OSMF hostname/IP
//* 2. Replace "yourpassword" with your actual password
//*    (or use certificate authentication)
//* 3. Replace "your-system-name" with your z/OS system name
//* 4. Adjust file paths in USS to match your environment
//* 5. The workflow key returned can be used to access the workflow
//*    in the z/OSMF web interface
//*
//* ALTERNATIVE METHODS TO START WORKFLOW:
//*
//* Method 1: Use z/OSMF Web UI
//*   - Navigate to Workflows in z/OSMF
//*   - Click "Create Workflow"
//*   - Browse to XML file location
//*   - Browse to properties file location
//*   - Complete the wizard
//*
//* Method 2: Use z/OSMF REST API with different authentication
//*   - SAF/PassTicket
//*   - Certificate-based authentication
//*   - JWT tokens
//*
//* Method 3: Use REXX/TSO commands (if available in your installation)
//*
//********************************************************************
