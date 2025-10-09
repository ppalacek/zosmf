//&JOB_PREFIX.02 JOB (&WORKFLOW_OWNER),'PROCESS DATA',                
//             CLASS=&JOB_CLASS,MSGCLASS=&MSGCLASS,                   
//             MSGLEVEL=(1,1),NOTIFY=&WORKFLOW_OWNER                  
//*                                                                  
//* JOB: DATA PROCESSING WITH MULTI-STEP LOGIC                     
//* DESC: Demonstrates complex JCL with conditional processing      
//* PARMS: HLQ, JOB_PREFIX, WORKFLOW_OWNER, ENVIRONMENT            
//*                                                                  
//JOBLIB   DD  DSN=SYS1.LINKLIB,DISP=SHR                           
//         DD  DSN=SYS1.CSSLIB,DISP=SHR                            
//*                                                                  
//* STEP 1: VALIDATE INPUT DATA                                     
//*                                                                  
//STEP01   EXEC PGM=ICEGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SORTMSG  DD  SYSOUT=*                                             
//SYSUT1   DD  DSN=&HLQ..CONTROL.CARDS,DISP=SHR                   
//SYSUT2   DD  DSN=&HLQ..TEMP.PROCESS,DISP=SHR                    
//SYSIN    DD  *                                                    
  SORT FIELDS=COPY                                                  
  INCLUDE COND=(1,8,CH,EQ,C'WORKFLOW')                             
/*                                                                  
//*                                                                  
//* STEP 2: GENERATE TEST DATA                                      
//*                                                                  
//STEP02   EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
RECORD001 TEST DATA FOR ENVIRONMENT &ENVIRONMENT                    
RECORD002 PROCESSING DATE: &CURRENT_DATE                           
RECORD003 PROCESSING TIME: &CURRENT_TIME                           
RECORD004 WORKFLOW OWNER: &WORKFLOW_OWNER                          
RECORD005 HIGH LEVEL QUALIFIER: &HLQ                               
RECORD006 JOB PREFIX: &JOB_PREFIX                                  
RECORD007 STATUS: DATA_GENERATION_COMPLETE                         
RECORD008 NEXT_STEP: DATA_VALIDATION                               
RECORD009 ENVIRONMENT_TYPE: &ENVIRONMENT                           
RECORD010 STEP_COMPLETION: SUCCESSFUL                              
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//SYSIN    DD  DUMMY                                                
//*                                                                  
//* STEP 3: SORT AND VALIDATE DATA                                  
//*                                                                  
//STEP03   EXEC PGM=SORT                                            
//SYSPRINT DD  SYSOUT=*                                             
//SORTMSG  DD  SYSOUT=*                                             
//SORTIN   DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//SORTOUT  DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//SYSIN    DD  *                                                    
  SORT FIELDS=(1,9,CH,A)                                           
  SUM FIELDS=NONE                                                   
  OUTREC FIELDS=(1,80,81:C'SORTED')                                
/*                                                                  
//*                                                                  
//* STEP 4: CONDITIONAL PROCESSING BY ENVIRONMENT                  
//*                                                                  
//IF04DEV  IF  (&ENVIRONMENT EQ 'DEV') THEN                        
//*                                                                  
//DEV01    EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
DEVELOPMENT ENVIRONMENT PROCESSING                                  
ADDITIONAL VALIDATION DISABLED FOR DEV                             
DEBUG MODE ENABLED                                                  
EXTENDED LOGGING ENABLED                                            
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=MOD                
//SYSIN    DD  DUMMY                                                
//*                                                                  
//DEV02    EXEC PGM=ICETOOL                                         
//TOOLMSG  DD  SYSOUT=*                                             
//DFSMSG   DD  SYSOUT=*                                             
//IN1      DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//OUT1     DD  DSN=&HLQ..BACKUP.&ENVIRONMENT,DISP=SHR             
//TOOLIN   DD  *                                                    
  COPY FROM(IN1) TO(OUT1)                                          
  COUNT FROM(IN1)                                                   
/*                                                                  
//ENDIF04D ENDIF                                                    
//*                                                                  
//IF04TST  IF  (&ENVIRONMENT EQ 'TEST') THEN                       
//*                                                                  
//TST01    EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
TEST ENVIRONMENT PROCESSING                                         
STANDARD VALIDATION ENABLED                                         
PERFORMANCE MONITORING ENABLED                                      
BACKUP CREATION ENABLED                                             
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=MOD                
//SYSIN    DD  DUMMY                                                
//*                                                                  
//TST02    EXEC PGM=ICETOOL                                         
//TOOLMSG  DD  SYSOUT=*                                             
//DFSMSG   DD  SYSOUT=*                                             
//IN1      DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//OUT1     DD  DSN=&HLQ..BACKUP.&ENVIRONMENT,DISP=SHR             
//OUT2     DD  SYSOUT=*                                             
//TOOLIN   DD  *                                                    
  COPY FROM(IN1) TO(OUT1)                                          
  COUNT FROM(IN1)                                                   
  DISPLAY FROM(IN1) LIST(OUT2) HEADER('TEST DATA VALIDATION')      
/*                                                                  
//TST03    EXEC PGM=SORT                                            
//SYSPRINT DD  SYSOUT=*                                             
//SORTMSG  DD  SYSOUT=*                                             
//SORTIN   DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//SORTOUT  DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SORT FIELDS=COPY                                                  
  INCLUDE COND=(81,6,CH,EQ,C'SORTED')                              
/*                                                                  
//ENDIF04T ENDIF                                                    
//*                                                                  
//IF04PRD  IF  (&ENVIRONMENT EQ 'PROD') THEN                       
//*                                                                  
//PRD01    EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
PRODUCTION ENVIRONMENT PROCESSING                                   
FULL VALIDATION ENABLED                                             
AUDIT LOGGING ENABLED                                               
MULTIPLE BACKUP COPIES CREATED                                      
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=MOD                
//SYSIN    DD  DUMMY                                                
//*                                                                  
//PRD02    EXEC PGM=ICETOOL                                         
//TOOLMSG  DD  SYSOUT=*                                             
//DFSMSG   DD  SYSOUT=*                                             
//IN1      DD  DSN=&HLQ..WORK.DATA,DISP=SHR                       
//OUT1     DD  DSN=&HLQ..BACKUP.&ENVIRONMENT,DISP=SHR             
//OUT2     DD  SYSOUT=*                                             
//OUT3     DD  DSN=&HLQ..BACKUP.PROD.COPY2,                       
//             DISP=(NEW,CATLG,DELETE),                             
//             SPACE=(CYL,(20,10)),                                 
//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=27920),               
//             UNIT=SYSDA,VOL=SER=*                                 
//TOOLIN   DD  *                                                    
  COPY FROM(IN1) TO(OUT1)                                          
  COPY FROM(IN1) TO(OUT3)                                          
  COUNT FROM(IN1)                                                   
  DISPLAY FROM(IN1) LIST(OUT2) HEADER('PROD DATA VALIDATION')      
/*                                                                  
//PRD03    EXEC PGM=IEHPROGM                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SCRATCH DSNAME=&HLQ..TEMP.PROCESS,VOL=SYSDA=*                   
  CATLG DSNAME=&HLQ..BACKUP.PROD.COPY2,VOL=SYSDA=*               
/*                                                                  
//ENDIF04P ENDIF                                                    
//*                                                                  
//* STEP 5: GENERATE SUMMARY REPORT                                
//*                                                                  
//STEP05   EXEC PGM=SORT                                            
//SYSPRINT DD  SYSOUT=*                                             
//SORTMSG  DD  SYSOUT=*                                             
//SORTIN   DD  DSN=&HLQ..LOG.&ENVIRONMENT,DISP=SHR                
//SORTOUT  DD  SYSOUT=*                                             
//SYSIN    DD  *                                                    
  SORT FIELDS=COPY                                                  
  OUTREC FIELDS=(C'*** WORKFLOW SUMMARY REPORT ***',/,             
                 C'ENVIRONMENT: ',C'&ENVIRONMENT',/,               
                 C'PROCESSING DATE: ',C'&CURRENT_DATE',/,          
                 C'PROCESSING TIME: ',C'&CURRENT_TIME',/,          
                 C'WORKFLOW OWNER: ',C'&WORKFLOW_OWNER',/,         
                 C'JOB PREFIX: ',C'&JOB_PREFIX',/,                 
                 C'HLQ: ',C'&HLQ',/,                               
                 C'*** LOG ENTRIES ***',/,                         
                 1,80)                                              
/*                                                                  
//*                                                                  
//* STEP 6: UPDATE STATUS                                           
//*                                                                  
//STEP06   EXEC PGM=IEBGENER                                        
//SYSPRINT DD  SYSOUT=*                                             
//SYSUT1   DD  *                                                    
WORKFLOW_STATUS=DATA_PROCESSING_COMPLETE                           
STEP_COUNT=6                                                        
LAST_STEP=DATA_PROCESSING                                           
COMPLETION_TIME=&CURRENT_TIME                                       
NEXT_PHASE=PYTHON_PROCESSING                                        
/*                                                                  
//SYSUT2   DD  DSN=&HLQ..CONTROL.CARDS,DISP=MOD                   
//SYSIN    DD  DUMMY                                                
//*