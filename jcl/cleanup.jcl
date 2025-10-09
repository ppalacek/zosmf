//&JOB_PREFIX.99 JOB (&WORKFLOW_OWNER),'CLEANUP',                   
//             CLASS=&JOB_CLASS,MSGCLASS=&MSGCLASS,                   
//             MSGLEVEL=(1,1),NOTIFY=&WORKFLOW_OWNER                  
//*                                                                  
//* JOB: CLEANUP TEMPORARY RESOURCES                               
//* DESC: Remove temporary datasets and clean up workflow          
//* PARMS: HLQ, JOB_PREFIX, WORKFLOW_OWNER, ENVIRONMENT            
//*                                                                  
//JOBLIB   DD  DSN=SYS1.LINKLIB,DISP=SHR                           
//         DD  DSN=SYS1.CSSLIB,DISP=SHR                            
//*                                                                  
//* STEP 1: GENERATE FINAL REPORT                                   
//*                                                                  
//STEP01   EXEC PGM=SORT                                            
//SYSPRINT DD  SYSOUT=*                                             
//SORTMSG  DD  SYSOUT=*                                             
//SORTIN   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=SHR                
//SORTOUT  DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SORT FIELDS=COPY                                                  
  OUTREC FIELDS=(C'================================',/,             
                 C'    WORKFLOW COMPLETION REPORT   ',/,            
                 C'================================',/,             
                 C'WORKFLOW ID: BASELINE_WORKFLOW_TEST',/,          
                 C'ENVIRONMENT: ',C'&ENVIRONMENT',/,               
                 C'COMPLETION DATE: ',C'&CURRENT_DATE',/,          
                 C'COMPLETION TIME: ',C'&CURRENT_TIME',/,          
                 C'WORKFLOW OWNER: ',C'&WORKFLOW_OWNER',/,         
                 C'JOB PREFIX: ',C'&JOB_PREFIX',/,                 
                 C'HLQ: ',C'&HLQ',/,                               
                 C'================================',/,             
                 C'         LOG SUMMARY             ',/,            
                 C'================================',/,             
                 1,80,/,                                            
                 C'================================',/,             
                 C'      END OF REPORT              ',/,            
                 C'================================')               
/*                                                                  
//*                                                                  
//* STEP 2: ARCHIVE LOG FILES                                       
//*                                                                  
//STEP02   EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=SHR                
//SYSUT2   DD  DSN=&HLQ..LOG.ARCHIVE.&ENVIRONMENT..G&CURRENT_JULDATE.V00,
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(CYL,(5,2)),                                   
//             DCB=(RECFM=VBA,LRECL=259,BLKSIZE=27998),             
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSIN    DD  DUMMY                                                
//*                                                                  
//* STEP 3: BACKUP CONTROL CARDS                                    
//*                                                                  
//STEP03   EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  DSN=&HLQ..CONTROL.CARDS,DISP=SHR                   
//SYSUT2   DD  DSN=&HLQ..CONTROL.BACKUP.&ENVIRONMENT..G&CURRENT_JULDATE.V00,
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(TRK,(5,2)),                                   
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),               
//             UNIT=SYSDA,VOL=SER=*                                 
//SYSIN    DD  DUMMY                                                
//*                                                                  
//* STEP 4: CONDITIONAL CLEANUP BASED ON ENVIRONMENT               
//*                                                                  
//IF04DEV  IF  (&ENVIRONMENT EQ 'DEV') THEN                        
//*                                                                  
//DEV01    EXEC PGM=IEHPROGM                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SCRATCH DSNAME=&HLQ..WORK.DATA,VOL=SYSDA=*                      
  SCRATCH DSNAME=&HLQ..TEMP.PROCESS,VOL=SYSDA=*                   
  SCRATCH DSNAME=&HLQ..CONTROL.CARDS,VOL=SYSDA=*                  
  SCRATCH DSNAME=&HLQ..LOG.&ENVIRONMENT,VOL=SYSDA=*               
/*                                                                  
//ENDIF04D ENDIF                                                    
//*                                                                  
//IF04TST  IF  (&ENVIRONMENT EQ 'TEST') THEN                       
//*                                                                  
//TST01    EXEC PGM=IEHPROGM                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SCRATCH DSNAME=&HLQ..WORK.DATA,VOL=SYSDA=*                      
  SCRATCH DSNAME=&HLQ..TEMP.PROCESS,VOL=SYSDA=*                   
  SCRATCH DSNAME=&HLQ..CONTROL.CARDS,VOL=SYSDA=*                  
/*                                                                  
//ENDIF04T ENDIF                                                    
//*                                                                  
//IF04PRD  IF  (&ENVIRONMENT EQ 'PROD') THEN                       
//*                                                                  
//PRD01    EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
PRODUCTION CLEANUP - PRESERVING DATASETS FOR AUDIT                 
BACKUP DATASETS WILL BE RETAINED PER RETENTION POLICY              
LOG DATASETS ARCHIVED FOR COMPLIANCE                               
/*                                                                  
//SYSUT2   DD  SYSOUT=*                                             
//SYSIN    DD  DUMMY                                                
//*                                                                  
//PRD02    EXEC PGM=IEHPROGM                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SCRATCH DSNAME=&HLQ..WORK.DATA,VOL=SYSDA=*                      
  SCRATCH DSNAME=&HLQ..TEMP.PROCESS,VOL=SYSDA=*                   
  SCRATCH DSNAME=&HLQ..CONTROL.CARDS,VOL=SYSDA=*                  
/*                                                                  
//ENDIF04P ENDIF                                                    
//*                                                                  
//* STEP 5: CATALOG CLEANUP                                         
//*                                                                  
//STEP05   EXEC PGM=IDCAMS                                          
//SYSPRINT DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  LISTCAT ENTRIES('&HLQ..**') ALL                                  
/*                                                                  
//*                                                                  
//* STEP 6: FINAL STATUS UPDATE                                     
//*                                                                  
//STEP06   EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
WORKFLOW_STATUS=CLEANUP_COMPLETE                                    
FINAL_STEP=CLEANUP                                                  
TOTAL_STEPS=6                                                       
CLEANUP_TIME=&CURRENT_TIME                                          
CLEANUP_DATE=&CURRENT_DATE                                          
WORKFLOW_RESULT=SUCCESS                                             
/*                                                                  
//SYSUT2   DD  SYSOUT=*                                             
//SYSIN    DD  DUMMY                                                
//*