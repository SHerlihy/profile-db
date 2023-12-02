#!/bin/bash

REDIS_SG_ID=$(terraform output -state=../database/terraform.tfstate -raw redis_sg_id)
REDIS_SNET_ID=`terraform output -state=../database/terraform.tfstate -raw public_subnet_1_id`

echo "REDIS_SG_ID"
echo $REDIS_SG_ID
echo "REDIS_SNET_ID"
echo $REDIS_SNET_ID

terraform apply -var="redis_sg_id=$REDIS_SG_ID" -var="redis_subnet_id=$REDIS_SNET_ID"
