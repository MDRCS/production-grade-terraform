#!/bin/bash

# user-data.sh is a script that is executed when the bastion server get startup.

sudo yum update -yum
sudo amazon-linux-extras install -y docker
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo usermod -aG docker ec2-user