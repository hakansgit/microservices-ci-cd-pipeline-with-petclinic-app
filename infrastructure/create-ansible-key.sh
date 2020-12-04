#!/bin/bash
PATH="$PATH:/usr/local/bin"
CFN_KEYPAIR="call-ansible.key"
AWS_REGION="us-east-1"
aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${CFN_KEYPAIR} --query "KeyMaterial" --output text > ${CFN_KEYPAIR}
chmod 400 ${CFN_KEYPAIR}
pwd
ls -al
cat ${CFN_KEYPAIR}