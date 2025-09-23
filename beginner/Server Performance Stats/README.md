# Server Performance Stats

<h3 align="center"> script to analyse basic linux server performance stats. </h3>

### When you say “run a Linux server,” there are a few contexts:

1.On your own computer (local VM or bare metal)
2.On a cloud provider (like AWS EC2, DigitalOcean, etc.)
3.Using containers (like Docker)

### here we Run a Linux Server on AWS EC2 (most common for DevOps)

create_ec2.sh

#### two levels of “status”

1- AWS EC2 status (cloud-level checks) → running, stopped, passed health checks.
Check EC2 instance status via AWS CLI (cloud level) -> check_ec2.sh

2- Inside the instance (OS-level status) → CPU, memory, uptime, etc.
Check Linux server status via SSH (inside the instance) -> check_linux.sh
