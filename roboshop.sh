#! /bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0d87e7256db5b1464"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z07718462X47NRO5PVN2N"
DOMAIN_NAME="viswak.shop"

for instance in ${INSTANCES[@]}
do 

INSTANCE_ID=$(aws ec2 run-instances \
 --image-id ami-0220d79f3f480ecf5\
 --instance-type t3.micro \
 --security-group-ids sg-0d87e7256db5b1464 \
 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test}]'\
 --query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    
    else
         IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

    fi 

        echo "$instance IP adress is : $IP"

    aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Creating or Updating a record set for cognito endpoint"
    ,"Changes": [{
      "Action"              : "UPSERT"
      ,"ResourceRecordSet"  : {
        "Name" : "'"$instance.$DOMAIN_NAME"'"
        ,"Type"             : "CNAME"
        ,"TTL"              : 120
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }'
    
done 