#!/bin/bash
#now i AM giving the names through command line

#Instancenames=("mongodb" "catalouge" "web" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payments" "dispatch")
Instancenames=$@
instance_Type=""
Imageid=ami-03265a0778a880afb
Securitygroup_id=sg-0512695d6d01b2c74
domain_name=devopsvani.online
for i in $@
do
    if [[ $i == "mongodb" || $i == "mysql" ]]
    then
        instance_Type="t3.micro"
    else
        instance_Type="t2.micro"
    fi
echo "Creating $i....."

#describe instances command

 $(aws ec2 describe-instances --filters "Name=tag:Name,Values=$i" | jq -r '.Reservations[0].Instances[0].Tags[] | select(.Key == "Name").Value')&>>/dev/null

   if [ $? -ne 0 ]
   then
    echo "$i Instance is not Created yet.lets Create it.........."
    private_IpAdress=$(aws ec2 run-instances --image-id $Imageid --instance-type $instance_Type --security-group-ids $Securitygroup_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]"|jq -r '.Instances[0].PrivateIpAddress')
    echo "Created $i : Ip Address : $private_IpAdress"
   else
    echo "$i Instance is already Created"
    fi

#private_IpAdress=$(aws ec2 run-instances --image-id $Imageid --instance-type $instance_Type --security-group-ids $Securitygroup_id --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]"|jq -r '.Instances[0].PrivateIpAddress')
#echo "Created $i : Ip Address : $private_IpAdress"



private_ip_route53_record=$(aws route53 list-resource-record-sets --hosted-zone-id "Z00901702AI0X0PSLUZQF" --query "ResourceRecordSets[?ends_with(Name, 'devopsvani.online.') && Type == 'A']"|jq -r ".[0].ResourceRecords[0].Value")

if [ $private_IpAdress -eq $private_ip_route53_record ]
then
         # Record exists and matches the expected IP
         echo "A record already exists with the expected IP address." 
else

 # Record doesn't exist or doesn't match the expected IP
   echo "A record does not exist or does not match the expected IP address."
   echo "Creating/updating the Record......"

   aws route53 change-resource-record-sets --hosted-zone-id Z00901702AI0X0PSLUZQF --change-batch '{
            "Comment": "CREATE/UPDATE A record",
            "Changes": [{
            "Action": "UPSERT",
                        "ResourceRecordSet": {
                                    "Name": "'$i.$domain_name'",
                                    "Type": "A",
                                    "TTL": 300,
                                 "ResourceRecords": [{ "Value": "'$private_IpAdress'"}]
}}]
}'
#echo "$i"
fi
done

#improvemnet
#check instances are already created or not
#checked route 53 records are already created , if created just update them otherwise create them


