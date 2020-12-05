#!/bin/bash
PATH="$PATH:/usr/local/bin"
CFN_KEYPAIR="call-ansible.key"
AWS_REGION="us-east-1"
aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${CFN_KEYPAIR} --query "KeyMaterial" --output text > ${CFN_KEYPAIR}
chmod 400 ${CFN_KEYPAIR}
pwd
ls -al
cat ${CFN_KEYPAIR}


# create stack

PATH="$PATH:/usr/local/bin"
APP_NAME="Petclinic"
APP_STACK_NAME="hkn-$APP_NAME-App-${BUILD_NUMBER}"
CFN_KEYPAIR="call-ansible.key"
CFN_TEMPLATE="./infrastructure/docker-swarm-infrastructure-cfn-template.yml"
AWS_REGION="us-east-1"
aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${APP_STACK_NAME} \
--capabilities CAPABILITY_IAM --template-body file://${CFN_TEMPLATE} \
--parameters ParameterKey=KeyPairName,ParameterValue=${CFN_KEYPAIR}

# Test ansible with dev dynamic inventory
APP_NAME="Petclinic"
CFN_KEYPAIR="call-ansible.key"
PATH="$PATH:/usr/local/bin"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${CFN_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
export APP_STACK_NAME="Call-$APP_NAME-App-${BUILD_NUMBER}"
# Dev Stack
sed -i "s/APP_STACK_NAME/$APP_STACK_NAME/" ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml
cat ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml
ansible-inventory -v -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml --graph
# Dev Stack Grand Master
sed -i "s/APP_STACK_NAME/$APP_STACK_NAME/" ./ansible/inventory/dev_stack_swarm_grand_master_aws_ec2.yaml
cat ./ansible/inventory/dev_stack_swarm_grand_master_aws_ec2.yaml
ansible-inventory -v -i ./ansible/inventory/dev_stack_swarm_grand_master_aws_ec2.yaml --graph
# Dev Stack Managers
sed -i "s/APP_STACK_NAME/$APP_STACK_NAME/" ./ansible/inventory/dev_stack_swarm_managers_aws_ec2.yaml
cat ./ansible/inventory/dev_stack_swarm_managers_aws_ec2.yaml
ansible-inventory -v -i ./ansible/inventory/dev_stack_swarm_managers_aws_ec2.yaml --graph
# Dev Stack Workers
sed -i "s/APP_STACK_NAME/$APP_STACK_NAME/" ./ansible/inventory/dev_stack_swarm_workers_aws_ec2.yaml
cat ./ansible/inventory/dev_stack_swarm_workers_aws_ec2.yaml
ansible-inventory -v -i ./ansible/inventory/dev_stack_swarm_workers_aws_ec2.yaml --graph

#init docker swarm 
PATH="$PATH:/usr/local/bin"
APP_NAME="Petclinic"
CFN_KEYPAIR="call-ansible.key"
APP_STACK_NAME="hkn-$APP_NAME-App-9"
export ANSIBLE_PRIVATE_KEY_FILE="${WORKSPACE}/${CFN_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING=False
sed -i "s/APP_STACK_NAME/$APP_STACK_NAME/" ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml
# Swarm Setup for all nodes (instances)
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_setup_for_all_docker_swarm_instances.yaml
# Swarm Setup for Grand Master node
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_initialize_docker_swarm.yaml
# Swarm Setup for Other Managers nodes
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_managers.yaml
# Swarm Setup for Workers nodes
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_workers.yaml

#tear down swarm