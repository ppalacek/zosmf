//&JOB_PREFIX.01 JOB (&WORKFLOW_OWNER),'CREATE DATASETS',               
//             CLASS=&JOB_CLASS,MSGCLASS=&MSGCLASS,                   
//             MSGLEVEL=(1,1),NOTIFY=&WORKFLOW_OWNER                  
//*                                                                  
//* JOB: CREATE DATASETS FOR WORKFLOW                               
//* DESC: Creates temporary datasets needed for workflow processing 
//* PARMS: HLQ, JOB_PREFIX, WORKFLOW_OWNER, JOB_CLASS, MSGCLASS    
//*                                                                  
//JOBLIB   DD  DSN=SYS1.LINKLIB,DISP=SHR                           
//         DD  DSN=SYS1.CSSLIB,DISP=SHR                            
//*                                                                  
//* STEP 1: CREATE WORK DATASET                                     
//*                                                                  
//STEP01   EXEC PGM=IEFBR14                                         
//WORKDS   DD  DSN=&HLQ..WORK.DATA,                                
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(CYL,(10,5)),                                  
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),               
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSPRINT DD  SYSOUT=*                                             
//*                                                                  
//* STEP 2: CREATE TEMP DATASET FOR PROCESSING                      
//*                                                                  
//STEP02   EXEC PGM=IEFBR14                                         
//TEMPDS   DD  DSN=&HLQ..TEMP.PROCESS,                             
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(CYL,(5,2)),                                   
//             DCB=(RECFM=FB,LRECL=133,BLKSIZE=27930),              
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSPRINT DD  SYSOUT=*                                             
//*                                                                  
//* STEP 3: CREATE LOG DATASET                                      
//*                                                                  
//STEP03   EXEC PGM=IEFBR14                                         
//LOGDS    DD  DSN=&HLQ..LOG.&ENVIRONMENT,                         
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(CYL,(3,1)),                                   
//             DCB=(RECFM=VBA,LRECL=259,BLKSIZE=27998),             
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSPRINT DD  SYSOUT=*                                             
//*                                                                  
//* STEP 4: CREATE CONTROL DATASET                                  
//*                                                                  
//STEP04   EXEC PGM=IEFBR14                                         
//CTLLDS   DD  DSN=&HLQ..CONTROL.CARDS,                            
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(TRK,(5,2)),                                   
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),               
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSPRINT DD  SYSOUT=*                                             
//*                                                                  
//* STEP 5: CREATE BACKUP DATASET                                   
//*                                                                  
//STEP05   EXEC PGM=IEFBR14                                         
//BACKDS   DD  DSN=&HLQ..BACKUP.&ENVIRONMENT,                      
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(CYL,(20,10)),                                 
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),               
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSPRINT DD  SYSOUT=*                                             
//*                                                                  
//* STEP 6: INITIALIZE CONTROL CARDS                                
//*                                                                  
//STEP06   EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
WORKFLOW_START_TIME=&CURRENT_TIME                                   
WORKFLOW_ENVIRONMENT=&ENVIRONMENT                                   
WORKFLOW_OWNER=&WORKFLOW_OWNER                                      
WORKFLOW_HLQ=&HLQ                                                   
WORKFLOW_STATUS=INITIALIZED                                         
STEP_COUNT=0                                                        
ERROR_COUNT=0                                                       
WARNING_COUNT=0                                                     
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..CONTROL.CARDS,DISP=SHR                   
//SYSIN    DD  DUMMY                                                
//*                                                                  
//* STEP 7: CONDITIONAL PROCESSING BASED ON ENVIRONMENT             
//*                                                                  
//STEP07   EXEC PGM=IDCAMS,COND=(0,NE)                             
//SYSPRINT DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  LISTCAT ENTRIES('&HLQ..**') ALL                                  
/*                                                                  
//IF07DEV  IF  (&ENVIRONMENT EQ 'DEV') THEN                        
//DEVSTEP  EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
DEVELOPMENT ENVIRONMENT INITIALIZATION COMPLETE                     
ADDITIONAL DEV-SPECIFIC PROCESSING CAN BE ADDED HERE               
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=MOD                
//SYSIN    DD  DUMMY                                                
//ENDIF07  ENDIF                                                    
//*                                                                  
//IF07TST  IF  (&ENVIRONMENT EQ 'TEST') THEN                       
//TSTSTEP  EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
TEST ENVIRONMENT INITIALIZATION COMPLETE                            
ADDITIONAL TEST-SPECIFIC PROCESSING CAN BE ADDED HERE              
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=MOD                
//SYSIN    DD  DUMMY                                                
//ENDIF07T ENDIF                                                    
//*                                                                  
//IF07PRD  IF  (&ENVIRONMENT EQ 'PROD') THEN                       
//PRDSTEP  EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
PRODUCTION ENVIRONMENT INITIALIZATION COMPLETE                      
ADDITIONAL PROD-SPECIFIC PROCESSING CAN BE ADDED HERE              
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=MOD                
//SYSIN    DD  DUMMY                                                
//ENDIF07P ENDIF                                                    
//*