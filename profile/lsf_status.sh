#!/bin/bash                                                                                                                                                                                                         
# Check LSF job status, return: running, success, or failed                                                                                                                                                         
job_id=$1                                                                                                                                                                                                           
stat=$(bjobs -noheader -o "stat" "$job_id" 2>/dev/null)                                                                                                                                                             
                                                                                                                                                                                                                    
case "$stat" in                                                                                                                                                                                                     
  PEND|RUN) echo "running" ;;                                                                                                                                                                                       
  DONE)     echo "success" ;;                                                                                                                                                                                       
  EXIT)     echo "failed" ;;                                                                                                                                                                                        
  "")       echo "success" ;;  # Job not in queue = completed                                                                                                                                                       
  *)        echo "failed" ;;                                                                                                                                                                                        
esac
