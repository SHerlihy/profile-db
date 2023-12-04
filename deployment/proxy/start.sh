#!/bin/bash

PROFILE_DB_VPC_ID=$(terraform output -state=../database/terraform.tfstate -raw profile_db_vpc_id)
REDIS_SNET_ID=`terraform output -state=../database/terraform.tfstate -raw public_subnet_1_id`

echo "PROFILE_DB_VPC_ID"
echo $PROFILE_DB_VPC_ID
echo "REDIS_SNET_ID"
echo $REDIS_SNET_ID

terraform apply -var="profile_db_vpc_id=$PROFILE_DB_VPC_ID" -var="redis_subnet_id=$REDIS_SNET_ID"
