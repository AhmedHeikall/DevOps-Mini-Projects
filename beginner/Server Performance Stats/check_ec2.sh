#!/bin/bash
INSTANCE_ID="i-0abcd1234efgh5678"   # replace with your instance id
REGION="us-east-1"                  # replace with your region

aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query "InstanceStatuses[*].[InstanceId,InstanceState.Name,SystemStatus.Status,InstanceStatus.Status]" \
  --output table
