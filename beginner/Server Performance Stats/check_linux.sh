#!/bin/bash
INSTANCE_IP="your-public-ip"
KEY="mykey.pem"
USER="ec2-user"   # Amazon Linux/RedHat → ec2-user, Ubuntu → ubuntu

ssh -i "$KEY" $USER@$INSTANCE_IP << 'EOF'
  echo "=== Uptime ==="
  uptime
  
  echo -e "\n=== CPU Usage ==="
  top -bn1 | grep "Cpu(s)"
  
  echo -e "\n=== Memory Usage ==="
  free -m
  
  echo -e "\n=== Disk Usage ==="
  df -h --total | grep total
EOF
