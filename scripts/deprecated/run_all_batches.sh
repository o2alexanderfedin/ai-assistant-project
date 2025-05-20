#!/bin/bash

# This script processes all issues in small batches to avoid timeouts

# Configure batch size
BATCH_SIZE=10
MAX_ISSUE_NUM=70  # Adjust this to the highest issue number

echo "Processing all issues in batches of $BATCH_SIZE..."

# Process batches
for ((START=1; START<=MAX_ISSUE_NUM; START+=BATCH_SIZE)); do
  END=$((START + BATCH_SIZE - 1))
  if [ $END -gt $MAX_ISSUE_NUM ]; then
    END=$MAX_ISSUE_NUM
  fi
  
  echo "========================================="
  echo "Processing batch from #$START to #$END"
  echo "========================================="
  
  python3 ./scripts/process_issue_batch.py $START $END
  
  echo "Batch completed. Waiting 5 seconds before next batch..."
  sleep 5
done

echo "🎉 All batches completed!"