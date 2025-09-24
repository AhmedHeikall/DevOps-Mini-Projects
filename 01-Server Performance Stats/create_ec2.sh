#!/bin/bash 

# VARIABLES
REGION="eu-north-1"
KEY_NAME="my_ec2_key"
KEY_FILE="/mnt/d/aws/key_files/${KEY_NAME}.ppk"
SECURITY_GROUP_NAME="my-ec2-sg"
AMI_ID="ami-0a716d3f3b16d290c"   # Ubuntu 22.04 LTS in eu-norh-1
INSTANCE_TYPE="t3.micro"
TAG_NAME="LinuxStatsServer"


#  1- CREATE KEY
create_key_pair () {
echo "[+] Checking for key pair: $KEY_NAME"
if aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION &>/dev/null; then
  echo "Key pair $KEY_NAME already exists. Skipping creation."
else
  echo "[+] Creating key pair..."
  aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --key-format ppk \
    --region $REGION \
    --query 'KeyMaterial' \
    --output text > $KEY_FILE
    # chmode -> change file permission , 400 -> owner read only, groups and others no
  # chmod 400 ${KEY_NAME}.ppk
  echo "Saved private key to ${KEY_NAME}.ppk"
fi
}

# 2- create securety-group and add rules
create_sg (){
echo "[+] Checking for security group: $SECURITY_GROUP_NAME"
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=$SECURITY_GROUP_NAME \
  --region $REGION \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || true)

if [[ "$SG_ID" == "None" || -z "$SG_ID" ]]; then
  echo "[+] Creating security group..."
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for EC2 server" \
    --region $REGION \
    --query 'GroupId' \
    --output text)
  echo "Created SG with ID: $SG_ID"

  # Allow SSH (22), HTTP (80)
  aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr <YOUR_IP> --region $REGION
  aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr <YOUR_IP> --region $REGION
else
  echo "Reusing existing SG with ID: $SG_ID"
fi
}

# 3- create EC2 instance 
create_ec2()  {
echo "[+] Checking if instance with tag $TAG_NAME already exists..."
# aws ec2 describe-instances → lists instances.
# --filters → finds instances with your Name tag.
# "Name=instance-state-name,Values=pending,running,stopping,stopped" → avoids terminated instances.
# grep -o 'i-[a-z0-9]\+' → extracts the instance ID (i-xxxxxxxxxxxx).

EXISTING_INSTANCE_ID=$(aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:Name,Values=$TAG_NAME" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text | grep -o 'i-[a-z0-9]\+')

if [ -n "$EXISTING_INSTANCE_ID" ]; then
  echo "[*] Instance already exists with ID: $EXISTING_INSTANCE_ID"
  INSTANCE_ID=$EXISTING_INSTANCE_ID
else
  echo "[+] Launching EC2 instance..."
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --region $REGION \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

  echo "Instance launched with ID: $INSTANCE_ID"
fi
}

# 4- get public ip
get_public_ip() {
echo "[+] Waiting for instance to run..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

echo "Instance is running at $PUBLIC_IP"
}



create_key_pair
create_sg
create_ec2
get_public_ip  
#  connect to ec2 using putty

# -----------------------------
# 5. Upload server-stats.sh
# -----------------------------
if [[ ! -f "$STATS_SCRIPT" ]]; then
  echo "[-] Error: $STATS_SCRIPT not found!"
  exit 1
fi

echo "[+] Uploading $STATS_SCRIPT to EC2..."
scp -o StrictHostKeyChecking=no -i ${KEY_NAME}.pem $STATS_SCRIPT ubuntu@$PUBLIC_IP:/home/ubuntu/

# -----------------------------
# 6. Run server-stats.sh remotely
# -----------------------------
echo "[+] Running server-stats.sh on EC2..."
ssh -o StrictHostKeyChecking=no -i ${KEY_NAME}.pem ubuntu@$PUBLIC_IP "chmod +x $STATS_SCRIPT && ./server-stats.sh"

echo "====================================="
echo " ✅ All done! Instance Public IP: $PUBLIC_IP"
echo " Connect manually with:"
echo " ssh -i ${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo "====================================="
