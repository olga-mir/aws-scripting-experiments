#!/bin/bash
set -e
set -u
source ./config.sh

instances_ids=$(aws ec2 run-instances \
  --count 3 \
  --instance-type t2.micro \
  --image-id $CONFIG_MY_AMI_IDS \
  --security-group-id $CONFIG_MY_SG_IDS \
  --key-name  $CONFIG_MY_KEY_NAME \
  --user-data file://ec2_bootstrap_static_server_instance.sh \
  --query "Instances[].InstanceId" \
  --output text)

echo "Instances created: " $instances_ids
echo "Waiting for the instances to become available"

aws ec2 wait instance-running \
  --instance-ids $instances_ids

echo "Instances Running"
echo "Public interfaces:"

aws ec2 describe-instances \
  --instance-ids $instances_ids \
  --query "Reservations[].Instances[].[AmiLaunchIndex, PublicDnsName, PublicIpAddress]" \
  --output table
