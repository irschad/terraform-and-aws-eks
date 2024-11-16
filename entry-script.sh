#!/bin/bash

# Install and start docker
sudo yum update -y && sudo yum install -y docker
sudo systemctl start docker

# Add ec2-user to docker group to allow it to call docker commands
sudo usermod -aG docker ec2-user

# Start a docker container running nginx
docker run -p 8080:80 nginx